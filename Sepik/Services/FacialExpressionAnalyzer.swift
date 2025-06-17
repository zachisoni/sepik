import Foundation
import Vision
import CoreML
import AVFoundation

class FacialExpressionAnalyzer {
    private let model: VNCoreMLModel

    init() throws {
        // Try multiple approaches to load the SmileDetection model
        let config = MLModelConfiguration()
        
        // First, try to load from the bundle as a compiled model
        if let modelURL = Bundle.main.url(forResource: "SmileDetection", withExtension: "mlmodelc") {
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            model = try VNCoreMLModel(for: mlModel)
        }
        // If that fails, try loading the .mlmodel file directly
        else if let modelURL = Bundle.main.url(forResource: "SmileDetection", withExtension: "mlmodel") {
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            model = try VNCoreMLModel(for: mlModel)
        }
        // If both fail, try loading without extension (let the system figure it out)
        else if let modelURL = Bundle.main.url(forResource: "SmileDetection", withExtension: nil) {
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            model = try VNCoreMLModel(for: mlModel)
        }
        else {
            // Last resort: list bundle contents for debugging
            let bundleContents = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) ?? []
            let modelFiles = bundleContents.filter { $0.lastPathComponent.contains("SmileDetection") }
            print("Available model files in bundle: \(modelFiles)")
            
            throw NSError(domain: "FacialExpressionAnalyzer", 
                         code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "SmileDetection model not found in bundle. Available files: \(bundleContents.map { $0.lastPathComponent })"])
        }
    }

    func analyze(videoURL: URL) async throws -> (smileFrames: Int, neutralFrames: Int) {
        let urlAsset = AVURLAsset(url: videoURL)
        let durationCM: CMTime = try await urlAsset.load(.duration)
        let duration = durationCM.seconds
        
        // Keep adaptive sampling but make it more conservative
        let sampleInterval: TimeInterval = duration < 30 ? 0.5 : (duration < 120 ? 1.0 : 1.5)
        
        let generator = AVAssetImageGenerator(asset: urlAsset)
        generator.appliesPreferredTrackTransform = true
        // Keep frame tolerances for faster extraction
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)

        var smileCount = 0
        var neutralCount = 0

        let times = stride(from: 0.0, to: duration, by: sampleInterval)
            .map { CMTime(seconds: $0, preferredTimescale: 600) }

        // Revert to sequential processing to avoid concurrency issues
        for time in times {
            do {
                let cgImage = try await generateCGImage(at: time, generator: generator)
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                let request = VNCoreMLRequest(model: model)
                try handler.perform([request])
                if let result = request.results?.first as? VNClassificationObservation {
                    // Updated logic for new model labels: "smile" and "non_smile"
                    switch result.identifier {
                    case "smile" where result.confidence >= 0.8: 
                        smileCount += 1
                    case "non_smile": 
                        neutralCount += 1
                    default: 
                        break
                    }
                }
            } catch {
                print("Error analyzing frame at \(time.seconds): \(error)")
                // Continue with next frame instead of failing completely
            }
        }

        return (smileCount, neutralCount)
    }
    
    private func generateCGImage(at time: CMTime, generator: AVAssetImageGenerator) async throws -> CGImage {
        try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: NSError(domain: "FacialExpressionAnalyzer", code: -1, userInfo: nil))
                }
            }
        }
    }
} 
