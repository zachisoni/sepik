//
//  VideoLoop.swift
//  Sepik
//
//  Created by Asad on 19/06/25.
//
import SwiftUI

struct FrameAnimationView: View {
    let totalFrames = 232
    let frameRate = 30.0 // FPS
    @State private var currentFrame = 1

    var body: some View {
        Image("loading_\(currentFrame)")
            .resizable()
            .scaledToFit()
            .onAppear {
                startAnimation()
                print("frame: ", currentFrame)
            }
    }

    func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { _ in
            var current = (currentFrame + 1) % totalFrames
            if current == 0 {
                current = 1
            }
            currentFrame = current
        }
    }
}

