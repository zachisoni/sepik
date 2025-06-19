import Foundation
import Speech
import AVFoundation

internal final class SpeechAnalyzer {
    private var recognizer: SFSpeechRecognizer?
    private let maxVideoLength: TimeInterval = 300.0 // 5 minutes max
    private let maxDirectProcessingLength: TimeInterval = 240.0 // 4 minutes - try direct first
    private var processingCount = 0 // Track how many videos we've processed

    init() {
        setupRecognizer()
    }
    
    /// Setup or refresh the speech recognizer
    private func setupRecognizer() {
        recognizer = SFSpeechRecognizer()
        print("Speech recognizer initialized/refreshed")
    }
    
    /// Reset the recognizer if it becomes unreliable
    private func resetRecognizer() {
        print("Resetting speech recognizer due to reliability issues")
        recognizer = nil
        
        // Small delay to let system recover
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            setupRecognizer()
        }
    }

    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Transcribe and analyze the speech in the video with hybrid approach
    func analyze(videoURL: URL) async throws -> (totalWords: Int, wpm: Double, fillerCounts: [String: Int]) {
        let urlAsset = AVURLAsset(url: videoURL)
        let durationCM: CMTime = try await urlAsset.load(.duration)
        let duration = durationCM.seconds
        let minutes = duration / 60.0

        // Check if video is too long
        guard duration <= maxVideoLength else {
            throw NSError(domain: "SpeechAnalyzer", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Video is too long. Maximum supported length is 5 minutes."
            ])
        }

        print("Starting speech analysis for video duration: \(duration) seconds (processing count: \(processingCount))")
        processingCount += 1
        
        // Reset recognizer periodically or if we detect issues
        if processingCount > 2 {
            print("Resetting recognizer after processing \(processingCount) videos")
            resetRecognizer()
            processingCount = 0
            
            // Wait for recognizer to be ready
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }

        let transcript: String
        
        // For videos > 2 minutes, try a more conservative approach first
        if duration > 120.0 {
            transcript = try await transcribeWithRecovery(videoURL: videoURL, duration: duration, isLongVideo: true)
        } else {
            transcript = try await transcribeWithRecovery(videoURL: videoURL, duration: duration, isLongVideo: false)
        }

        print("Raw transcript: '\(transcript)'")
        print("Transcript length: \(transcript.count) characters")

        // Check if transcript is empty or too short
        guard !transcript.isEmpty else {
            print("WARNING: Empty transcript received")
            return (0, 0.0, [:])
        }

        // Process the transcript
        let words = transcript.split { $0.isWhitespace || $0.isNewline }
        let total = words.count
        
        print("Total words found: \(total)")

        // Early return if no words found
        guard total > 0 else {
            print("WARNING: No words found in transcript")
            return (0, 0.0, [:])
        }

        // Count all words and phrases
        var wordCounts: [String: Int] = [:]
        let cleanedWords = words.map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
        
        print("Cleaned words sample (first 10): \(Array(cleanedWords.prefix(10)))")
        
        // Count individual words
        for word in cleanedWords {
            // Skip very short words (1-2 characters) and common words that aren't fillers
            if word.count >= 2 && !isCommonWord(word) {
                wordCounts[word, default: 0] += 1
            }
        }
        
        print("Word counts (non-common words): \(wordCounts.count) unique words")
        
        // Count multi-word filler phrases in the full text
        let fullText = cleanedWords.joined(separator: " ")
        let multiWordFillers = ["you know", "kind of", "sort of", "i mean", "you see"]
        for phrase in multiWordFillers {
            let occurrences = fullText.components(separatedBy: phrase).count - 1
            if occurrences > 0 {
                wordCounts[phrase] = occurrences
                print("Found multi-word filler '\(phrase)': \(occurrences) times")
            }
        }
        
        // Identify filler words using two criteria:
        // 1. Predefined common filler words (any occurrence)
        // 2. Dynamic detection: words that appear >= 5 times per minute (restored original threshold)
        var fillerCounts: [String: Int] = [:]
        
        // First, check for predefined filler words
        for (word, count) in wordCounts {
            if isPredefinedFillerWord(word) {
                fillerCounts[word] = count
                print("Found predefined filler '\(word)': \(count) times")
            }
        }
        
        // Then, check for dynamic filler words (high frequency) - restored original logic
        for (word, count) in wordCounts {
            let wordsPerMinute = Double(count) / minutes
            // Restored original threshold: ≥5 per minute and ≥5 total occurrences
            if wordsPerMinute >= 5.0 && count >= 5 && !fillerCounts.keys.contains(word) {
                fillerCounts[word] = count
                print("Found dynamic filler '\(word)': \(count) times (\(wordsPerMinute) per minute)")
            }
        }

        let wpm = Double(total) / minutes
        print("Speech analysis completed: \(total) words, \(wpm) WPM, \(fillerCounts.count) filler types")
        print("Filler words found: \(fillerCounts)")
        return (total, wpm, fillerCounts)
    }
    
    /// Transcribe with recovery mechanisms
    private func transcribeWithRecovery(videoURL: URL, duration: TimeInterval, isLongVideo: Bool) async throws -> String {
        // First attempt: Direct transcription
        do {
            if isLongVideo {
                print("Attempting conservative direct transcription for long video...")
                return try await transcribeDirectWithConservativeTimeout(url: videoURL, duration: duration)
            } else {
                print("Attempting direct transcription for short video...")
                return try await transcribeDirectWithTimeout(url: videoURL, duration: duration)
            }
        } catch {
            print("Direct transcription failed: \(error)")
            
            // If it's a Speech Framework error 209, try to recover
            let nsError = error as NSError
            if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 209 {
                print("Detected Speech Framework degradation (error 209), attempting recovery...")
                
                // Reset recognizer and try one more time with shorter timeout
                resetRecognizer()
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds recovery
                
                do {
                    print("Retry attempt with fresh recognizer...")
                    return try await transcribeDirectWithConservativeTimeout(url: videoURL, duration: min(duration, 60.0))
                } catch {
                    print("Recovery attempt failed: \(error)")
                    
                    // Only use chunking for longer videos as last resort
                    if duration > 60.0 {
                        print("Falling back to very small chunks...")
                        return try await transcribeInVerySmallChunks(videoURL: videoURL, duration: duration)
                    } else {
                        // For short videos, give up gracefully
                        throw NSError(domain: "SpeechAnalyzer", code: 1010, userInfo: [
                            NSLocalizedDescriptionKey: "Speech recognition system is temporarily unavailable. Please try again later."
                        ])
                    }
                }
            } else {
                throw error
            }
        }
    }
    
    /// Conservative direct transcription with shorter timeout for reliability
    private func transcribeDirectWithConservativeTimeout(url: URL, duration: TimeInterval) async throws -> String {
        // Much shorter timeout for reliability
        let timeoutSeconds = min(60.0, duration + 20.0)
        print("Using conservative direct transcription with \(timeoutSeconds)s timeout")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true // Use on-device for reliability
            
            // Use an atomic flag to ensure continuation is only resumed once
            let continuationState = ContinuationState()
            
            // Conservative timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                await continuationState.tryResume {
                    continuation.resume(throwing: NSError(domain: "SpeechAnalyzer", code: 1004, userInfo: [
                        NSLocalizedDescriptionKey: "Speech recognition timed out after \(Int(timeoutSeconds)) seconds"
                    ]))
                }
            }
            
            let recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
                Task {
                    if let error = error {
                        await continuationState.tryResume {
                            timeoutTask.cancel()
                            continuation.resume(throwing: error)
                        }
                    } else if let result = result, result.isFinal {
                        await continuationState.tryResume {
                            timeoutTask.cancel()
                            continuation.resume(returning: result.bestTranscription.formattedString)
                        }
                    }
                    // If result is not final and no error, we wait for more callbacks
                }
            }
            
            // Handle case where task creation fails
            if recognitionTask == nil {
                Task {
                    await continuationState.tryResume {
                        timeoutTask.cancel()
                        continuation.resume(throwing: NSError(domain: "SpeechAnalyzer", code: 1005, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to create speech recognition task"
                        ]))
                    }
                }
            }
        }
    }
    
    /// Very small chunks (15 seconds) as absolute last resort
    private func transcribeInVerySmallChunks(videoURL: URL, duration: TimeInterval) async throws -> String {
        print("Using very small chunks (15s) as last resort for \(duration) second video")
        
        let chunkDuration: TimeInterval = 15.0 // Very small chunks
        let numberOfChunks = Int(ceil(duration / chunkDuration))
        var allTranscripts: [String] = []
        var successfulChunks = 0
        
        for chunkIndex in 0..<numberOfChunks {
            let startTime = Double(chunkIndex) * chunkDuration
            let endTime = min(startTime + chunkDuration, duration)
            
            print("Processing small chunk \(chunkIndex + 1)/\(numberOfChunks): \(startTime)s to \(endTime)s")
            
            do {
                // Extract audio chunk
                let chunkURL = try await extractAudioChunk(
                    from: videoURL, 
                    startTime: startTime, 
                    endTime: endTime, 
                    chunkIndex: chunkIndex
                )
                
                // Transcribe with very short timeout
                let chunkTranscript = try await transcribeVerySmallChunk(url: chunkURL)
                print("Small chunk \(chunkIndex + 1) transcript: '\(chunkTranscript)' (length: \(chunkTranscript.count))")
                
                if !chunkTranscript.isEmpty {
                    allTranscripts.append(chunkTranscript)
                    successfulChunks += 1
                }
                
                // Clean up temporary file
                try? FileManager.default.removeItem(at: chunkURL)
                
                // Longer delay to let system recover
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
            } catch {
                print("Error processing small chunk \(chunkIndex): \(error)")
                // Continue with other chunks
            }
        }
        
        let finalTranscript = allTranscripts.joined(separator: " ")
        print("Very small chunk transcription complete: \(successfulChunks)/\(numberOfChunks) chunks successful")
        
        // Accept even fewer successful chunks
        if successfulChunks < max(1, numberOfChunks / 4) {
            throw NSError(domain: "SpeechAnalyzer", code: 1006, userInfo: [
                NSLocalizedDescriptionKey: "Speech recognition system appears to be unavailable (\(successfulChunks)/\(numberOfChunks) chunks successful)"
            ])
        }
        
        return finalTranscript
    }
    
    /// Transcribe very small chunk with minimal timeout
    private func transcribeVerySmallChunk(url: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true // On-device for reliability
            
            let continuationState = ContinuationState()
            
            // Very short timeout for small chunks
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds timeout
                await continuationState.tryResume {
                    continuation.resume(throwing: NSError(domain: "SpeechAnalyzer", code: 1004, userInfo: [
                        NSLocalizedDescriptionKey: "Small chunk transcription timed out"
                    ]))
                }
            }
            
            let recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
                Task {
                    if let error = error {
                        await continuationState.tryResume {
                            timeoutTask.cancel()
                            continuation.resume(throwing: error)
                        }
                    } else if let result = result, result.isFinal {
                        await continuationState.tryResume {
                            timeoutTask.cancel()
                            continuation.resume(returning: result.bestTranscription.formattedString)
                        }
                    }
                }
            }
            
            if recognitionTask == nil {
                Task {
                    await continuationState.tryResume {
                        timeoutTask.cancel()
                        continuation.resume(throwing: NSError(domain: "SpeechAnalyzer", code: 1005, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to create small chunk recognition task"
                        ]))
                    }
                }
            }
        }
    }
    
    /// Direct transcription with adaptive timeout based on video length
    private func transcribeDirectWithTimeout(url: URL, duration: TimeInterval) async throws -> String {
        // Calculate timeout based on video duration (minimum 60s, maximum 120s)
        let timeoutSeconds = min(max(duration + 30, 60), 120)
        print("Using direct transcription with \(timeoutSeconds)s timeout")
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = false // Use cloud for better accuracy
            
            // Use an atomic flag to ensure continuation is only resumed once
            let continuationState = ContinuationState()
            
            // Add timeout protection with adaptive timeout
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                await continuationState.tryResume {
                    continuation.resume(throwing: NSError(domain: "SpeechAnalyzer", code: 1004, userInfo: [
                        NSLocalizedDescriptionKey: "Speech recognition timed out after \(Int(timeoutSeconds)) seconds"
                    ]))
                }
            }
            
            let recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
                Task {
                    if let error = error {
                        await continuationState.tryResume {
                            timeoutTask.cancel()
                            continuation.resume(throwing: error)
                        }
                    } else if let result = result, result.isFinal {
                        await continuationState.tryResume {
                            timeoutTask.cancel()
                            continuation.resume(returning: result.bestTranscription.formattedString)
                        }
                    }
                    // If result is not final and no error, we wait for more callbacks
                }
            }
            
            // Handle case where task creation fails
            if recognitionTask == nil {
                Task {
                    await continuationState.tryResume {
                        timeoutTask.cancel()
                        continuation.resume(throwing: NSError(domain: "SpeechAnalyzer", code: 1005, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to create speech recognition task"
                        ]))
                    }
                }
            }
        }
    }
    
    /// Extract audio chunk from video
    private func extractAudioChunk(from videoURL: URL, startTime: TimeInterval, endTime: TimeInterval, chunkIndex: Int) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        
        print("Extracting audio chunk \(chunkIndex): \(startTime)s to \(endTime)s")
        
        // Verify the asset has audio tracks
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw NSError(domain: "SpeechAnalyzer", code: 1007, userInfo: [
                NSLocalizedDescriptionKey: "No audio tracks found in video"
            ])
        }
        print("Found \(audioTracks.count) audio track(s)")
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "SpeechAnalyzer", code: 1002, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create export session"
            ])
        }
        
        // Set time range
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 600)
        exportSession.timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
        
        // Set output
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("speech_chunk_\(chunkIndex).m4a")
        
        // Remove existing file if it exists
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        print("Exporting audio chunk to: \(outputURL.path)")
        
        // Use the new iOS 18 async method if available, fallback to older method
        if #available(iOS 18.0, *) {
            try await exportSession.export(to: outputURL, as: .m4a)
        } else {
            await exportSession.export()
            if let error = exportSession.error {
                throw error
            }
        }
        
        // Verify the exported file exists and has content
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: outputURL.path) else {
            throw NSError(domain: "SpeechAnalyzer", code: 1008, userInfo: [
                NSLocalizedDescriptionKey: "Exported audio file does not exist"
            ])
        }
        
        let attributes = try fileManager.attributesOfItem(atPath: outputURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        print("Audio chunk \(chunkIndex) exported successfully: \(fileSize) bytes")
        
        guard fileSize > 1000 else { // At least 1KB
            throw NSError(domain: "SpeechAnalyzer", code: 1009, userInfo: [
                NSLocalizedDescriptionKey: "Exported audio file is too small (\(fileSize) bytes)"
            ])
        }
        
        return outputURL
    }
    
    /// Check if a word is a predefined filler word
    private func isPredefinedFillerWord(_ word: String) -> Bool {
        let predefinedFillers = [
            "uh", "um", "ah", "er", "eh", "em", "hm", "hmm", "mmm",
            "like", "you know", "so", "well", "actually", "uhh", "umh",
            "basically", "literally", "obviously", "totally",
            "kind of", "sort of", "i mean", "you see",
            "right", "okay", "alright", "anyway"
        ]
        return predefinedFillers.contains(word)
    }
    
    /// Check if a word is a common word that shouldn't be considered a filler
    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = [
            "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by",
            "is", "are", "was", "were", "be", "been", "being", "have", "has", "had",
            "do", "does", "did", "will", "would", "could", "should", "can", "may", "might",
            "this", "that", "these", "those", "it", "he", "she", "we", "they", "you", "i",
            "my", "your", "his", "her", "our", "their", "me", "him", "her", "us", "them",
            "what", "when", "where", "why", "how", "who", "which", "there", "here",
            "yes", "no", "not", "very", "really", "just", "only", "also", "even", "still"
        ]
        return commonWords.contains(word)
    }
}

/// Actor to safely manage continuation state in async contexts
private actor ContinuationState {
    private var hasResumed = false
    
    func tryResume(_ resumeAction: () -> Void) {
        guard !hasResumed else { return }
        hasResumed = true
        resumeAction()
    }
} 

