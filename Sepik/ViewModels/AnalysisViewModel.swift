import Foundation
import AVFoundation
import SwiftData

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var result: AnalysisResult?
    @Published var errorMessage: String?
    @Published var analysisProgress: Double = 0.0
    @Published var currentStep: String = ""

    private let videoURL: URL
    private let facialAnalyzer: FacialExpressionAnalyzer
    private let speechAnalyzer: SpeechAnalyzer
    private let eyeContactAnalyzer: EyeContactAnalyzer
    var dataManager: DataManager?

    init(videoURL: URL, modelContext: ModelContext? = nil) {
        self.videoURL = videoURL
        do {
            facialAnalyzer = try FacialExpressionAnalyzer()
        } catch {
            fatalError("Failed to load CoreML model: \(error)")
        }
        speechAnalyzer = SpeechAnalyzer()
        eyeContactAnalyzer = EyeContactAnalyzer()
        
        if let modelContext = modelContext {
            self.dataManager = DataManager(modelContext: modelContext)
        }
    }

    func analyze() async {
        isProcessing = true
        analysisProgress = 0.0
        
        do {
            currentStep = "Requesting authorization..."
            analysisProgress = 0.1
            
            let authorized = await speechAnalyzer.requestAuthorization()
            guard authorized else {
                throw NSError(domain: "Speech recognition not authorized", code: 1)
            }

            currentStep = "Analyzing video..."
            analysisProgress = 0.2
            
            // Keep concurrent execution but simplify progress tracking
            async let facial = facialAnalyzer.analyze(videoURL: videoURL)
            async let speech = speechAnalyzer.analyze(videoURL: videoURL)
            async let eyeContact = eyeContactAnalyzer.analyze(videoURL: videoURL)

            analysisProgress = 0.7
            
            let (smileFrames, neutralFrames) = try await facial
            let (totalWords, wpm, fillerCounts) = try await speech
            let eyeContactScore = try await eyeContact

            currentStep = "Finalizing results..."
            analysisProgress = 0.9

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
                videoURL: videoURL,
                eyeContactScore: eyeContactScore
            )
            result = analysis
            
            // Save to SwiftData
            dataManager?.savePracticeSession(analysis)
            
            currentStep = "Complete!"
            analysisProgress = 1.0
            
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
        isProcessing = false
    }
} 