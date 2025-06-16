import Foundation
import Speech
import AVFoundation

class SpeechAnalyzer {
    private let recognizer = SFSpeechRecognizer()

    /// Request speech recognition authorization
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Transcribe and analyze the speech in the video
    func analyze(videoURL: URL) async throws -> (totalWords: Int, wpm: Double, fillerCounts: [String: Int]) {
        let urlAsset = AVURLAsset(url: videoURL)
        let durationCM: CMTime = try await urlAsset.load(.duration)
        let duration = durationCM.seconds
        let minutes = duration / 60.0

        let transcript = try await transcribe(url: videoURL)
        let words = transcript.split { $0.isWhitespace || $0.isNewline }
        let total = words.count

        // Count all words and phrases
        var wordCounts: [String: Int] = [:]
        let cleanedWords = words.map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
        
        // Count individual words
        for word in cleanedWords {
            // Skip very short words (1-2 characters) and common words that aren't fillers
            if word.count >= 2 && !isCommonWord(word) {
                wordCounts[word, default: 0] += 1
            }
        }
        
        // Count multi-word filler phrases
        let fullText = cleanedWords.joined(separator: " ")
        let multiWordFillers = ["you know", "kind of", "sort of", "i mean", "you see"]
        for phrase in multiWordFillers {
            let occurrences = fullText.components(separatedBy: phrase).count - 1
            if occurrences > 0 {
                wordCounts[phrase] = occurrences
            }
        }
        
        // Identify filler words using two criteria:
        // 1. Predefined common filler words (any occurrence)
        // 2. Dynamic detection: words that appear >= 5 times per minute
        var fillerCounts: [String: Int] = [:]
        
        // First, check for predefined filler words
        for (word, count) in wordCounts {
            if isPredefinedFillerWord(word) {
                fillerCounts[word] = count
            }
        }
        
        // Then, check for dynamic filler words (high frequency)
        for (word, count) in wordCounts {
            let wordsPerMinute = Double(count) / minutes
            // Only include words that truly meet the threshold (≥5 per minute)
            // and have at least 5 total occurrences to avoid false positives in short videos
            if wordsPerMinute >= 5.0 && count >= 5 && !fillerCounts.keys.contains(word) {
                fillerCounts[word] = count
            }
        }

        let wpm = Double(total) / minutes
        return (total, wpm, fillerCounts)
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

    private func transcribe(url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            // Set longer timeout for longer videos
            request.shouldReportPartialResults = false
            
            let _ = recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
} 
