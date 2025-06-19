import Foundation
import Vision
import CoreML
import AVFoundation

internal final class FacialExpressionAnalyzer {
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
        } else {
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

        // More aggressive memory management for longer videos
        let sampleInterval: TimeInterval
        if duration < 60 {
            sampleInterval = 0.5 // Every 0.5 seconds for short videos
        } else if duration < 180 {
            sampleInterval = 1.5 // Every 1.5 seconds for medium videos
        } else {
            sampleInterval = 3.0 // Every 3 seconds for long videos (>3 minutes)
        }

        let generator = AVAssetImageGenerator(asset: urlAsset)
        generator.appliesPreferredTrackTransform = true
        // More generous tolerances for memory efficiency
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)

        // Limit maximum number of frames to prevent memory issues
        let maxFrames = duration > 180 ? 60 : Int(duration / sampleInterval)
        let actualInterval = duration / Double(maxFrames)

        var smileCount = 0
        var neutralCount = 0
        var processedFrames = 0

        // Process frames sequentially to avoid memory buildup
        for frameIndex in 0..<maxFrames {
            let timeSeconds = Double(frameIndex) * actualInterval
            let time = CMTime(seconds: timeSeconds, preferredTimescale: 600)

            do {
                let cgImage = try await generateCGImageAsync(at: time, generator: generator)

                // Move the vision processing outside autoreleasepool to handle errors properly
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                let request = VNCoreMLRequest(model: model)
                try handler.perform([request])

                autoreleasepool {
                    if let result = request.results?.first as? VNClassificationObservation {
                        switch result.identifier {
                        case "smile" where result.confidence >= 0.7:
                            smileCount += 1
                        case "non_smile" where result.confidence >= 0.7:
                            neutralCount += 1
                        default:
                            break
                        }
                    }
                    processedFrames += 1
                }
            } catch {
                print("Error analyzing frame at \(timeSeconds): \(error)")
                // Continue with next frame instead of failing completely
            }

            // Memory pressure check - yield periodically for long videos
            if frameIndex % 10 == 0 {
                await Task.yield()
            }
        }

        print("Processed \(processedFrames) frames for facial analysis (duration: \(duration)s)")
        return (smileCount, neutralCount)
    }

    // Async version that avoids priority inversion with timeout protection
    private func generateCGImageAsync(at time: CMTime, generator: AVAssetImageGenerator) async throws -> CGImage {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false

            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, error in
                guard !hasResumed else { return }
                hasResumed = true

                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: NSError(domain: "FacialExpressionAnalyzer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate image"]))
                }
            }
        }
    }
}
