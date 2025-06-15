import Foundation
import Vision
import CoreML
import AVFoundation

class FacialExpressionAnalyzer {
    private let model: VNCoreMLModel

    init() throws {
        let config = MLModelConfiguration()
        let mlModel = try FacialGestures(configuration: config).model
        model = try VNCoreMLModel(for: mlModel)
    }

    func analyze(videoURL: URL) async throws -> (smileFrames: Int, neutralFrames: Int) {
        let urlAsset = AVURLAsset(url: videoURL)
        let durationCM: CMTime = try await urlAsset.load(.duration)
        let duration = durationCM.seconds
        let sampleInterval: TimeInterval = 1.0

        let generator = AVAssetImageGenerator(asset: urlAsset)
        generator.appliesPreferredTrackTransform = true

        var smileCount = 0
        var neutralCount = 0

        let timesCM = stride(from: 0.0, to: duration, by: sampleInterval)
            .map { CMTime(seconds: $0, preferredTimescale: 600) }
        let timesValues = timesCM.map { NSValue(time: $0) }

        for value in timesValues {
            let time = value.timeValue
            let cgImage = try await generateCGImage(at: time, generator: generator)
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNCoreMLRequest(model: model)
            try handler.perform([request])
            if let result = request.results?.first as? VNClassificationObservation {
                // Only count as smile if confidence is very high (>= 0.8)
                switch result.identifier {
                case "smile" where result.confidence >= 0.8: smileCount += 1
                case "neutral": neutralCount += 1
                default: break
                }
            }
        }

        return (smileCount, neutralCount)
    }

    private func generateCGImage(at time: CMTime,
                                 generator: AVAssetImageGenerator) async throws -> CGImage {
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
