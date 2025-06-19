import Foundation
import AVFoundation
import SwiftData

@MainActor
internal class AnalysisViewModel: ObservableObject {
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

            currentStep = "Starting analysis..."
            analysisProgress = 0.15
            
            // Run analyses concurrently but track progress better
            currentStep = "Analyzing facial expressions, speech, and eye contact..."
            analysisProgress = 0.2
            
            // Start all analyses concurrently
            async let facial = facialAnalyzer.analyze(videoURL: videoURL)
            async let speech = speechAnalyzer.analyze(videoURL: videoURL)
            async let eyeContact = eyeContactAnalyzer.analyze(videoURL: videoURL)
            
            // Wait for first one to complete
            let (smileFrames, neutralFrames) = try await facial
            currentStep = "Facial analysis complete, continuing with speech and eye contact..."
            analysisProgress = 0.4
            
            // Wait for second one to complete
            let speechResult = try await speech
            currentStep = "Speech analysis complete, finishing eye contact analysis..."
            analysisProgress = 0.7
            
            // Wait for the last one
            let eyeContactScore = try await eyeContact
            currentStep = "All analysis complete, finalizing results..."
            analysisProgress = 0.9

            let urlAsset = AVURLAsset(url: videoURL)
            let durationCM: CMTime = try await urlAsset.load(.duration)
            let duration = durationCM.seconds

            let analysis = AnalysisResult(
                duration: duration,
                smileFrames: smileFrames,
                neutralFrames: neutralFrames,
                totalWords: speechResult.totalWords,
                wpm: speechResult.wpm,
                fillerCounts: speechResult.fillerCounts,
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
