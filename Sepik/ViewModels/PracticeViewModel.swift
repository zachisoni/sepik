//
//  PracticeViewModel.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

@MainActor
internal class PracticeViewModel: ObservableObject {
    @Published var selectedVideo: URL?
    @Published var isVideoUploaded = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedItem: PhotosPickerItem?
    @Published var isPickerPresented = false

    var canProceed: Bool {
        isVideoUploaded && !isLoading
    }

    func onSelectedItemChanged(oldValue: PhotosPickerItem?, newValue: PhotosPickerItem?) {
        guard let result = newValue else {
            errorMessage = "No video selected."
            return
        }
        loadVideo(from: result)
    }

    private func loadVideo(from result: PhotosPickerItem) {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // Add some delay to show loading state
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                let movie = try await withTimeout(seconds: 60) {
                    try await result.loadTransferable(type: Video.self)
                }

                guard let movie = movie else {
                    throw VideoError.loadFailed
                }

                guard movie.url.pathExtension.lowercased() == "mov" else {
                    throw VideoError.invalidFormat
                }

                let asset = AVURLAsset(url: movie.url)
                let duration = try await asset.load(.duration)
                let durationInSeconds = CMTimeGetSeconds(duration)
                guard durationInSeconds <= 600 else { // Increased to 10 minutes
                    throw VideoError.durationTooLong
                }

                selectedVideo = movie.url
                isVideoUploaded = true
            } catch {
                print("Video loading error: \(error)")
                if let videoError = error as? VideoError {
                    errorMessage = videoError.localizedDescription
                } else if error.localizedDescription.contains("too large") {
                    errorMessage = VideoError.fileTooLarge.localizedDescription
                } else if error.localizedDescription.contains("copy") || error.localizedDescription.contains("transfer") {
                    errorMessage = VideoError.transferFailed.localizedDescription
                } else {
                    errorMessage = "Failed to load the video: \(error.localizedDescription)"
                }
                isVideoUploaded = false
                selectedVideo = nil
            }

            isLoading = false
        }
    }

    private func cleanupTemporaryFile() {
        guard let videoURL = selectedVideo else { return }
        do {
            try FileManager.default.removeItem(at: videoURL)
            selectedVideo = nil
            isVideoUploaded = false
        } catch {
            print("Failed to delete temporary file: \(error.localizedDescription)")
        }
    }

            enum VideoError: LocalizedError {
        case invalidFormat
        case durationTooLong
        case loadFailed
        case timeout
        case fileTooLarge
        case transferFailed

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "Only MOV videos are supported."
            case .durationTooLong: return "Video duration exceeds 10 minutes."
            case .loadFailed: return "Failed to load the video."
            case .timeout: return "Video loading timed out. Please try with a smaller video file."
            case .fileTooLarge: return "Video file is too large (max 5GB)."
            case .transferFailed: return "Failed to transfer video file. Please try again."
            }
        }
    }

    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T?) async throws -> T? {
        try await withThrowingTaskGroup(of: T?.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw VideoError.timeout
            }
            
            // Wait for the first task to complete
            for try await result in group {
                group.cancelAll()
                return result
            }
            
            throw VideoError.timeout
        }
    }
}
