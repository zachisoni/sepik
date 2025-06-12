import Foundation

class VideoInputViewModel: ObservableObject {
    @Published var videoURL: URL?

    /// Whether the user can proceed to analysis
    var canProceed: Bool {
        videoURL != nil
    }
} 