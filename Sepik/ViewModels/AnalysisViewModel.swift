import Foundation
import AVFoundation
import SwiftData

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var result: AnalysisResult?
    @Published var errorMessage: String?

    private let videoURL: URL
    private let facialAnalyzer: FacialExpressionAnalyzer
    private let speechAnalyzer: SpeechAnalyzer
    var dataManager: DataManager?

    init(videoURL: URL, modelContext: ModelContext? = nil) {
        self.videoURL = videoURL
        do {
            facialAnalyzer = try FacialExpressionAnalyzer()
        } catch {
            fatalError("Failed to load CoreML model: \(error)")
        }
        speechAnalyzer = SpeechAnalyzer()
        
        if let modelContext = modelContext {
            self.dataManager = DataManager(modelContext: modelContext)
        }
    }

    func analyze() async {
        isProcessing = true
        do {
            let authorized = await speechAnalyzer.requestAuthorization()
            guard authorized else {
                throw NSError(domain: "Speech recognition not authorized", code: 1)
            }

            async let facial = facialAnalyzer.analyze(videoURL: videoURL)
            async let speech = speechAnalyzer.analyze(videoURL: videoURL)

            let (smileFrames, neutralFrames) = try await facial
            let (totalWords, wpm, fillerCounts) = try await speech

            let urlAsset = AVURLAsset(url: videoURL)
            let durationCM: CMTime = try await urlAsset.load(.duration)
            let duration = durationCM.seconds

            let analysis = AnalysisResult(
                duration: duration,
                smileFrames: smileFrames,
                neutralFrames: neutralFrames,
                totalWords: totalWords,
                wpm: wpm,
                fillerCounts: fillerCounts,
                videoURL: videoURL
            )
            result = analysis
            
            // Save to SwiftData
            dataManager?.savePracticeSession(analysis)
            
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
        isProcessing = false
    }
} 