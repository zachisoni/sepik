import Foundation
import Vision
import AVFoundation
import UIKit

class FaceDetectionService {
    static let shared = FaceDetectionService()
    
    private init() {}
    
    /// Validates if the video contains human faces by sampling frames
    func validateVideoContainsFace(url: URL) async throws -> Bool {
        let asset = AVURLAsset(url: url)
        
        // Get video duration and calculate sample times
        let duration = try await asset.load(.duration)
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        // Sample frames at different intervals (beginning, middle, end)
        let sampleTimes: [CMTime] = [
            CMTime(seconds: min(2.0, durationInSeconds * 0.1), preferredTimescale: 600),  // Near beginning
            CMTime(seconds: durationInSeconds * 0.5, preferredTimescale: 600),            // Middle
            CMTime(seconds: max(durationInSeconds - 2.0, durationInSeconds * 0.9), preferredTimescale: 600) // Near end
        ]
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 600)
        
        var faceDetectedCount = 0
        
        for time in sampleTimes {
            do {
                let cgImage = try await generator.image(at: time).image
                let hasFace = try await detectFaceInImage(cgImage)
                if hasFace {
                    faceDetectedCount += 1
                }
            } catch {
                print("Failed to generate frame at time \(time): \(error)")
                continue
            }
        }
        
        // Consider video valid if face is detected in at least 2 out of 3 samples
        return faceDetectedCount >= 2
    }
    
    /// Detects faces in a single image using Vision framework
    private func detectFaceInImage(_ cgImage: CGImage) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: false)
                    return
                }
                
                // Check if we found at least one face with reasonable confidence
                let validFaces = results.filter { face in
                    face.confidence > 0.5 && // Minimum confidence threshold
                    face.boundingBox.width > 0.1 && // Minimum face size (10% of image width)
                    face.boundingBox.height > 0.1   // Minimum face size (10% of image height)
                }
                
                continuation.resume(returning: !validFaces.isEmpty)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum FaceDetectionError: LocalizedError {
    case noFaceDetected
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .noFaceDetected:
            return "No face detected in the video. Please upload a video where your face is clearly visible."
        case .processingFailed:
            return "Failed to process the video for face detection. Please try again."
        }
    }
} 