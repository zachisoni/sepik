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
            analysisProgress += 0.05
            
            let authorized = await speechAnalyzer.requestAuthorization()
            guard authorized else {
                throw NSError(domain: "Speech recognition not authorized", code: 1)
            }

            currentStep = "Starting analysis..."
            analysisProgress += 0.1
            
            // Run analyses concurrently but track progress better
            currentStep = "Analyzing facial expressions, speech, and eye contact..."
            
            // Start all analyses concurrently
            async let facial = facialAnalyzer.analyze(videoURL: videoURL){ progress in
                await MainActor.run {
                    self.currentStep = "Facial analysis complete, continuing with speech and eye contact..."
                    self.analysisProgress += (progress / 4)
                    print("progress face :", self.analysisProgress)
                }
            }
            async let speech = speechAnalyzer.analyze(videoURL: videoURL){
                await MainActor.run {
                    self.analysisProgress += 0.05
                    print("progress speech:", self.analysisProgress)
                }
            }
            async let eyeContact = eyeContactAnalyzer.analyze(videoURL: videoURL){ progress in
                await MainActor.run {
                    self.currentStep = "All analysis complete, finalizing results..."
                    self.analysisProgress += (progress / 3)
                    print("progress eye:", self.analysisProgress)
                }
            }
            
            // Wait for first one to complete
            let (smileFrames, neutralFrames) = try await facial
//            analysisProgress = 0.3
            // Wait for second one to complete
            let (totalWords, wpm, fillerCounts) = try await speech
//            analysisProgress = 0.6
            // Wait for the last one
            let eyeContactScore = try await eyeContact
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
            analysisProgress = 0.95
            
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
