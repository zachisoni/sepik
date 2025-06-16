import AVFoundation
import Vision
import UIKit

func extractFrames(from videoURL: URL, fps: Int, completion: @escaping ([(image: UIImage, orientation: CGImagePropertyOrientation)]) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        var frames: [(image: UIImage, orientation: CGImagePropertyOrientation)] = []
        let asset = AVAsset(url: videoURL)

        guard let track = asset.tracks(withMediaType: .video).first else {
            print("ERROR: Tidak dapat menemukan video track.")
            DispatchQueue.main.async { completion([]) }
            return
        }
        let preferredTransform = track.preferredTransform
        let videoOrientation = orientation(from: preferredTransform)

        let duration = CMTimeGetSeconds(asset.duration)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let frameCount = Int(duration * Double(fps))
        for i in 0..<frameCount {
            let time = CMTime(seconds: Double(i) / Double(fps), preferredTimescale: 600)
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                frames.append((image: UIImage(cgImage: cgImage), orientation: videoOrientation))
            } catch {
                print("ERROR: Gagal mengekstrak frame \(i): \(error.localizedDescription)")
            }
        }
        DispatchQueue.main.async {
            completion(frames)
        }
    }
}

enum EyeContactStatus {
    case lookingForward
    case lookingAway
    case faceNotDetected
}

func analyzeFrameForEyeContact(
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

        // --- THRESHOLD KEPALA ---
        let yaw = face.yaw?.doubleValue ?? 0.0
        let pitch = face.pitch?.doubleValue ?? 0.0
        let headPoseThreshold: Double = 0.25 // Nilai lebih realistis

        if abs(yaw) > headPoseThreshold || abs(pitch) > headPoseThreshold {
            print(String(format: "ANALYSIS: Gagal, kepala menyamping. Yaw: %.2f, Pitch: %.2f", yaw, pitch))
            completion(.lookingAway)
            return
        }

        // --- ATURAN MATA ---
        guard let leftPupil = face.landmarks?.leftPupil,
              let leftEye = face.landmarks?.leftEye,
              leftPupil.pointCount > 0,
              leftEye.pointCount > 0 else {
            print("ANALYSIS: Gagal, landmark mata/pupil tidak ditemukan.")
            completion(.lookingAway) // <-- DIUBAH MENJADI .lookingAway
            return
        }

        let pupilCenter = getCenter(for: leftPupil)
        let eyeCenter = getCenter(for: leftEye)
        let normalizedEyeWidth = getNormalizedWidth(for: leftEye)

        guard normalizedEyeWidth > 0 else {
            print("ANALYSIS: Gagal, lebar mata ternormalisasi adalah nol.")
            completion(.lookingAway)
            return
        }

        let horizontalDistance = abs(pupilCenter.x - eyeCenter.x)
        let pupilPositionThreshold: CGFloat = 0.20 // Threshold yang wajar
        let thresholdDistance = normalizedEyeWidth * pupilPositionThreshold

        if horizontalDistance > thresholdDistance {
            print(String(format: "ANALYSIS: Gagal, mata melirik. Jarak: %.4f, Ambang Batas: %.4f", horizontalDistance, thresholdDistance))
            completion(.lookingAway)
        } else {
            print("ANALYSIS: SUKSES, kontak mata terjaga.")
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

// MARK: - Scoring Logic

func calculatePublicSpeakingScore(
    from videoURL: URL,
    onFrameProcessed: ((UIImage) -> Void)? = nil,
    completion: @escaping (Double) -> Void
) {
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

            DispatchQueue.main.async {
                onFrameProcessed?(uiImage)
            }

            guard let cgImage = uiImage.cgImage else { continue }

            dispatchGroup.enter()
            analyzeFrameForEyeContact(image: cgImage, orientation: orientation) { status in
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

func getCenter(for landmark: VNFaceLandmarkRegion2D) -> CGPoint {
    let points = landmark.normalizedPoints
    guard !points.isEmpty else { return .zero }
    let x = points.map { $0.x }.reduce(0, +) / CGFloat(points.count)
    let y = points.map { $0.y }.reduce(0, +) / CGFloat(points.count)
    return CGPoint(x: x, y: y)
}

func getNormalizedWidth(for landmark: VNFaceLandmarkRegion2D) -> CGFloat {
    let points = landmark.normalizedPoints
    guard let minX = points.map({ $0.x }).min(),
          let maxX = points.map({ $0.x }).max() else {
        return 0
    }
    return maxX - minX
}

func orientation(from transform: CGAffineTransform) -> CGImagePropertyOrientation {
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
