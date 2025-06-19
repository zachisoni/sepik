import Foundation
import AVFoundation
import SwiftData

@MainActor
internal final class AnalysisViewModel: ObservableObject {
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
            
            // Run analyses concurrently with better progress tracking
            currentStep = "Analyzing facial expressions, speech, and eye contact..."
            analysisProgress = 0.2
            
            // Start all analyses concurrently with progress callbacks
            async let facial = facialAnalyzer.analyze(videoURL: videoURL) { progress in
                await MainActor.run {
                    self.currentStep = "Analyzing facial expressions..."
                    self.analysisProgress = 0.2 + (progress * 0.2) // 20% of total progress
                    print("progress face :", self.analysisProgress)
                }
            }
            async let speech = speechAnalyzer.analyze(videoURL: videoURL) {
                await MainActor.run {
                    self.currentStep = "Analyzing speech patterns..."
                    self.analysisProgress += 0.05
                    print("progress speech:", self.analysisProgress)
                }
            }
            async let eyeContact = eyeContactAnalyzer.analyze(videoURL: videoURL) { progress in
                await MainActor.run {
                    self.currentStep = "Analyzing eye contact..."
                    self.analysisProgress = 0.6 + (progress * 0.2) // Final 20% of analysis
                    print("progress eye:", self.analysisProgress)
                }
            }
            
            // Wait for facial analysis to complete
            let (smileFrames, neutralFrames) = try await facial
            currentStep = "Facial analysis complete, continuing with speech and eye contact..."
            analysisProgress = 0.4
            
            // Wait for speech analysis to complete
            let (totalWords, wpm, fillerCounts) = try await speech
            currentStep = "Speech analysis complete, finishing eye contact analysis..."
            analysisProgress = 0.7
            
            // Wait for eye contact analysis to complete
            let eyeContactScore = try await eyeContact
            currentStep = "All analysis complete, finalizing results..."
            analysisProgress = 0.9

            let urlAsset = AVURLAsset(url: videoURL)
            let durationCM: CMTime = try await urlAsset.load(.duration)
            let duration = durationCM.seconds
            
            analysisProgress = 0.95

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
