import Foundation
import AVFoundation
import SwiftData

internal struct AnalysisResults {
    let facial: (Int, Int)
    let totalWords: Int
    let wpm: Double
    let fillerCounts: [String: Int]
    let eyeContact: Double
}

@MainActor
internal final class AnalysisViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var result: AnalysisResult?
    @Published var errorMessage: String?
    @Published var analysisProgress: Double = 0.0
    @Published var currentStep: String = ""
    @Published var shouldShowNotFoundView = false

    private let videoURL: URL
    private let facialAnalyzer: FacialExpressionAnalyzer
    private let speechAnalyzer: SpeechAnalyzer
    private let eyeContactAnalyzer: EyeContactAnalyzer
    private let faceDetectionService = FaceDetectionService.shared
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
        errorMessage = nil // Clear any previous error
        result = nil // Clear any previous result

        do {
            try await performAnalysis()
        } catch {
            let errorDescription = (error as NSError).localizedDescription
            print("Analysis failed with error: \(errorDescription)")
            errorMessage = "Analysis failed: \(errorDescription)"
            currentStep = "Analysis failed"
        }
        isProcessing = false
    }

    private func performAnalysis() async throws {
        // First, validate that the video contains a face
        currentStep = "Validating video content..."
        analysisProgress = 0.05
        
        let containsFace = try await faceDetectionService.validateVideoContainsFace(url: videoURL)
        if !containsFace {
            shouldShowNotFoundView = true
            currentStep = "No face detected"
            analysisProgress = 0.0
            isProcessing = false
            return
        }
        
        currentStep = "Requesting authorization..."
        analysisProgress = 0.1

        let authorized = await speechAnalyzer.requestAuthorization()
        guard authorized else {
            throw NSError(domain: "SepikAnalysis", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition permission required"])
        }

        currentStep = "Starting analysis..."
        analysisProgress = 0.15

        let analysisResults = try await runAnalyses()
        try await processResults(from: analysisResults)
    }

    private func runAnalyses() async throws -> AnalysisResults {
        currentStep = "Analyzing facial expressions, speech, and eye contact..."
        analysisProgress = 0.2

        // Check video duration to decide on analysis strategy
        let urlAsset = AVURLAsset(url: videoURL)
        let durationCM: CMTime = try await urlAsset.load(.duration)
        let duration = durationCM.seconds

        // For long videos (>3 minutes), run analyses sequentially to save memory
        if duration > 180 {
            return try await runAnalysesSequentially()
        } else {
            return try await runAnalysesConcurrently()
        }
    }

    private func runAnalysesConcurrently() async throws -> AnalysisResults {
        // Start all analyses concurrently for shorter videos
        async let facial = facialAnalyzer.analyze(videoURL: videoURL)
        async let speech = speechAnalyzer.analyze(videoURL: videoURL)
        async let eyeContact = eyeContactAnalyzer.analyze(videoURL: videoURL)

        // Wait for facial analysis to complete
        currentStep = "Analyzing facial expressions..."
        let (smileFrames, neutralFrames) = try await facial
        currentStep = "Facial analysis complete, continuing with speech and eye contact..."
        analysisProgress = 0.4

        // Wait for speech analysis to complete
        currentStep = "Analyzing speech patterns..."
        let (totalWords, wpm, fillerCounts) = try await speech
        currentStep = "Speech analysis complete, finishing eye contact analysis..."
        analysisProgress = 0.7

        // Wait for eye contact analysis to complete
        currentStep = "Analyzing eye contact..."
        let eyeContactScore = try await eyeContact
        currentStep = "All analysis complete, finalizing results..."
        analysisProgress = 0.9

        return AnalysisResults(
            facial: (smileFrames, neutralFrames),
            totalWords: totalWords,
            wpm: wpm,
            fillerCounts: fillerCounts,
            eyeContact: eyeContactScore
        )
    }

    private func runAnalysesSequentially() async throws -> AnalysisResults {
        // Run analyses one by one for long videos to reduce memory pressure
        currentStep = "Analyzing facial expressions..."
        analysisProgress = 0.3

        print("Starting facial analysis for sequential processing...")
        let (smileFrames, neutralFrames) = try await facialAnalyzer.analyze(videoURL: videoURL)
        print("Facial analysis completed: \(smileFrames) smile frames, \(neutralFrames) neutral frames")

        // Force memory cleanup between analyses
        await Task.yield()

        currentStep = "Analyzing speech patterns..."
        analysisProgress = 0.6

        print("Starting speech analysis for sequential processing...")
        let (totalWords, wpm, fillerCounts) = try await speechAnalyzer.analyze(videoURL: videoURL)
        print("Speech analysis completed: \(totalWords) words, \(wpm) wpm")

        // Force memory cleanup between analyses
        await Task.yield()

        currentStep = "Analyzing eye contact..."
        analysisProgress = 0.8

        print("Starting eye contact analysis for sequential processing...")
        let eyeContactScore = try await eyeContactAnalyzer.analyze(videoURL: videoURL)
        print("Eye contact analysis completed: \(eyeContactScore)% score")

        currentStep = "All analysis complete, finalizing results..."
        analysisProgress = 0.9

        return AnalysisResults(
            facial: (smileFrames, neutralFrames),
            totalWords: totalWords,
            wpm: wpm,
            fillerCounts: fillerCounts,
            eyeContact: eyeContactScore
        )
    }

    private func processResults(from analysisResults: AnalysisResults) async throws {
        let urlAsset = AVURLAsset(url: videoURL)
        let durationCM: CMTime = try await urlAsset.load(.duration)
        let duration = durationCM.seconds

        analysisProgress = 0.95

        let analysis = AnalysisResult(
            duration: duration,
            smileFrames: analysisResults.facial.0,
            neutralFrames: analysisResults.facial.1,
            totalWords: analysisResults.totalWords,
            wpm: analysisResults.wpm,
            fillerCounts: analysisResults.fillerCounts,
            videoURL: videoURL,
            eyeContactScore: analysisResults.eyeContact
        )
        result = analysis

        // Save to SwiftData
        dataManager?.savePracticeSession(analysis)

        currentStep = "Complete!"
        analysisProgress = 1.0
    }
}
