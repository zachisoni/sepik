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
class PracticeViewModel: ObservableObject {
    @Published var selectedVideo: URL? = nil
    @Published var isVideoUploaded = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedItem: PhotosPickerItem? = nil
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
                let movie = try await withTimeout(seconds: 10) {
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
                guard durationInSeconds <= 300 else {
                    throw VideoError.durationTooLong
                }

                selectedVideo = movie.url
                isVideoUploaded = true
            } catch {
                errorMessage = error.localizedDescription
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

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "Only MOV videos are supported."
            case .durationTooLong: return "Video duration exceeds 5 minutes."
            case .loadFailed: return "Failed to load the video."
            case .timeout: return "Video loading timed out."
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
                return nil
            }
            guard let result = try await group.next() else {
                throw VideoError.timeout
            }
            group.cancelAll()
            return result
        }
    }
}
