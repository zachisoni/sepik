import Foundation
import AVFoundation
import Vision
import UIKit

internal class EyeContactAnalyzer {
    
    enum EyeContactStatus {
        case lookingForward
        case lookingAway
        case faceNotDetected
    }
    
    // MARK: - Public Interface
    
    func analyze(videoURL: URL) async throws -> Double {
        return await withCheckedContinuation { continuation in
            calculateEyeContactScore(from: videoURL) { score in
                continuation.resume(returning: score)
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func calculateEyeContactScore(
        from videoURL: URL,
        completion: @escaping (Double) -> Void
    ) {
        // Keep adaptive FPS but use sequential processing
        extractFrames(from: videoURL, fps: 2) { framesWithOrientation in
            guard !framesWithOrientation.isEmpty else {
                completion(0.0)
                return
            }

            var forwardCount = 0
            var analyzedFrameCount = 0
            let dispatchGroup = DispatchGroup()

            for frameData in framesWithOrientation {
                let uiImage = frameData.image
                let orientation = frameData.orientation

                guard let cgImage = uiImage.cgImage else { continue }

                dispatchGroup.enter()
                self.analyzeFrameForEyeContact(image: cgImage, orientation: orientation) { status in
                    if status == .lookingForward { forwardCount += 1 }
                    if status != .faceNotDetected { analyzedFrameCount += 1 }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                guard analyzedFrameCount > 0 else {
                    completion(0.0)
                    return
                }
                let score = (Double(forwardCount) / Double(analyzedFrameCount)) * 100.0
                completion(score)
            }
        }
    }
    
    private func extractFrames(from videoURL: URL, fps: Int, completion: @escaping ([(image: UIImage, orientation: CGImagePropertyOrientation)]) -> Void) {
        Task {
            var frames: [(image: UIImage, orientation: CGImagePropertyOrientation)] = []
            let asset = AVURLAsset(url: videoURL)

            do {
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let track = tracks.first else {
                    print("ERROR: Cannot find video track.")
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                let preferredTransform = try await track.load(.preferredTransform)
                let videoOrientation = self.orientation(from: preferredTransform)

                let duration = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(duration)
                
                // Keep adaptive FPS but more conservative
                let adaptiveFPS = durationSeconds < 60 ? 1.5 : 1.0
                
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                // Keep tolerances but less aggressive
                generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
                generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)

                let frameCount = min(Int(durationSeconds * adaptiveFPS), 60) // Reduce max frames
                
                // Revert to sequential frame extraction for reliability
                for frameIndex in 0..<frameCount {
                    let time = CMTime(seconds: Double(frameIndex) / adaptiveFPS, preferredTimescale: 600)
                    do {
                        let cgImage = try await generator.image(at: time).image
                        frames.append((image: UIImage(cgImage: cgImage), orientation: videoOrientation))
                    } catch {
                        print("ERROR: Failed to extract frame \(frameIndex): \(error.localizedDescription)")
                        // Continue with next frame
                    }
                }
                
                DispatchQueue.main.async {
                    completion(frames)
                }
            } catch {
                print("ERROR: Failed to load video asset properties: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
    
    private func analyzeFrameForEyeContact(
        image: CGImage,
        orientation: CGImagePropertyOrientation,
        completion: @escaping (EyeContactStatus) -> Void
    ) {
        let request = VNDetectFaceLandmarksRequest { request, error in
            if let error = error {
                print("Vision request failed: \(error)")
                completion(.faceNotDetected)
                return
            }

            guard let observations = request.results as? [VNFaceObservation],
                  let face = observations.first else {
                completion(.faceNotDetected)
                return
            }

            // Head pose threshold
            let yaw = face.yaw?.doubleValue ?? 0.0
            let pitch = face.pitch?.doubleValue ?? 0.0
            let headPoseThreshold: Double = 0.25

            if abs(yaw) > headPoseThreshold || abs(pitch) > headPoseThreshold {
                completion(.lookingAway)
                return
            }

            // Eye position analysis
            guard let leftPupil = face.landmarks?.leftPupil,
                  let leftEye = face.landmarks?.leftEye,
                  leftPupil.pointCount > 0,
                  leftEye.pointCount > 0 else {
                completion(.lookingAway)
                return
            }

            let pupilCenter = self.getCenter(for: leftPupil)
            let eyeCenter = self.getCenter(for: leftEye)
            let normalizedEyeWidth = self.getNormalizedWidth(for: leftEye)

            guard normalizedEyeWidth > 0 else {
                completion(.lookingAway)
                return
            }

            let horizontalDistance = abs(pupilCenter.x - eyeCenter.x)
            let pupilPositionThreshold: CGFloat = 0.20
            let thresholdDistance = normalizedEyeWidth * pupilPositionThreshold

            if horizontalDistance > thresholdDistance {
                completion(.lookingAway)
            } else {
                completion(.lookingForward)
            }
        }

        request.revision = VNDetectFaceLandmarksRequestRevision3
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Vision request error: \(error)")
            completion(.faceNotDetected)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getCenter(for landmark: VNFaceLandmarkRegion2D) -> CGPoint {
        let points = landmark.normalizedPoints
        guard !points.isEmpty else { return .zero }
        let centerX = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
        let centerY = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
        return CGPoint(x: centerX, y: centerY)
    }

    private func getNormalizedWidth(for landmark: VNFaceLandmarkRegion2D) -> CGFloat {
        let points = landmark.normalizedPoints
        guard let minX = points.map({ $0.x }).min(),
              let maxX = points.map({ $0.x }).max() else {
            return 0
        }
        return maxX - minX
    }

    private func orientation(from transform: CGAffineTransform) -> CGImagePropertyOrientation {
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            return .right
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            return .left
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            return .down
        } else {
            return .up
        }
    }
} 
