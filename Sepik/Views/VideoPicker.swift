import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        init(_ parent: VideoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let itemProvider = results.first?.itemProvider,
                  itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
                return
            }
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                guard let url = url else { return }
                let tmpURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: tmpURL)
                do {
                    try FileManager.default.copyItem(at: url, to: tmpURL)
                    DispatchQueue.main.async {
                        self.parent.videoURL = tmpURL
                    }
                } catch {
                    print("Error copying video: \(error)")
                }
            }
        }
    }
} 