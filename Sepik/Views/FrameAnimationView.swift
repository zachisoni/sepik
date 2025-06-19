//
//  VideoLoop.swift
//  Sepik
//
//  Created by Asad on 19/06/25.
//
import SwiftUI

internal struct FrameAnimationView: View {
    private let totalFrames = 232
    private let frameRate = 24.0 // Reduced from 30 FPS for better performance
    @State private var currentFrame = 1
    @State private var timer: Timer?
    @State private var imageCache: [Int: UIImage] = [:]
    private let maxCacheSize = 15 // Only cache 15 frames at a time
    private let isActive: Bool

    // Default initializer for backward compatibility
    init(isActive: Bool = true) {
        self.isActive = isActive
    }

    var body: some View {
        Group {
            if let cachedImage = imageCache[currentFrame] {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("loading_\(currentFrame)")
                    .resizable()
                    .scaledToFit()
                    .onAppear {
                        preloadFrame(currentFrame)
                    }
            }
        }
        .onAppear {
            if isActive {
                startAnimation()
                preloadNearbyFrames()
            }
        }
        .onDisappear {
            stopAnimation()
            clearCache()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimation()
                preloadNearbyFrames()
            } else {
                stopAnimation()
            }
        }
    }

    private func startAnimation() {
        // Don't start if animation is already running or if not active
        guard timer == nil && isActive else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { _ in
            let nextFrame = (currentFrame % totalFrames) + 1
            currentFrame = nextFrame

            // Preload next few frames
            preloadNearbyFrames()

            // Clean up old frames from cache
            cleanupCache()
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }

    private func preloadFrame(_ frameNumber: Int) {
        guard imageCache[frameNumber] == nil else { return }

        if let image = UIImage(named: "loading_\(frameNumber)") {
            imageCache[frameNumber] = image
        }
    }

    private func preloadNearbyFrames() {
        let preloadRange = 3 // Preload 3 frames ahead

        for index in 0..<preloadRange {
            let frameToLoad = ((currentFrame + index - 1) % totalFrames) + 1
            preloadFrame(frameToLoad)
        }
    }

    private func cleanupCache() {
        guard imageCache.count > maxCacheSize else { return }

        // Keep only frames near current frame
        let keepRange = 5
        let framesToKeep = Set((0..<keepRange).map {
            ((currentFrame + $0 - keepRange/2 - 1 + totalFrames) % totalFrames) + 1
        })

        imageCache = imageCache.filter { framesToKeep.contains($0.key) }
    }

    private func clearCache() {
        imageCache.removeAll()
    }
}
