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

        // Count all words first
        var wordCounts: [String: Int] = [:]
        for raw in words {
            let word = raw.lowercased().trimmingCharacters(in: .punctuationCharacters)
            // Skip very short words (1-2 characters) and common words that aren't fillers
            if word.count >= 2 && !isCommonWord(word) {
                wordCounts[word, default: 0] += 1
            }
        }
        
        // Identify filler words: words that appear >= 5 times per minute
        var fillerCounts: [String: Int] = [:]
        for (word, count) in wordCounts {
            let wordsPerMinute = Double(count) / minutes
            // Only include words that truly meet the threshold (≥5 per minute)
            // and have at least 5 total occurrences to avoid false positives in short videos
            if wordsPerMinute >= 5.0 && count >= 5 {
                fillerCounts[word] = count
            }
        }

        let wpm = Double(total) / minutes
        return (total, wpm, fillerCounts)
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
