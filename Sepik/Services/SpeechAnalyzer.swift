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

        let transcript = try await transcribe(url: videoURL)
        let words = transcript.split { $0.isWhitespace || $0.isNewline }
        let total = words.count

        let fillerWords = ["uh", "like", "you know"]
        var counts: [String: Int] = [:]
        fillerWords.forEach { counts[$0] = 0 }
        for raw in words {
            let w = raw.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if fillerWords.contains(w) {
                counts[w, default: 0] += 1
            }
        }

        let wpm = Double(total) / (duration / 60)
        return (total, wpm, counts)
    }

    private func transcribe(url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
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