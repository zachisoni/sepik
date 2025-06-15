import SwiftUI
import PhotosUI 
import Vision

struct EyeContactAnalysisView: View {
    // MARK: - State Properties
    @State private var videoURL: URL?
    @State private var score: Double?
    @State private var isAnalyzing = false
    @State private var showingPicker = false
    @State private var errorAlertMessage: String?
    @State private var currentFrameForDebug: UIImage?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // --- Bagian Judul ---
                Text("Analyzer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Frekuensi kontak mata")
                    .foregroundColor(.secondary)
                
                // << --- BAGIAN DEBUG VISUAL --- >>
                if let debugImage = currentFrameForDebug {
                    Image(uiImage: debugImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .background(Color.black)
                        .border(Color.red, width: 2)
                        .padding(.horizontal)
                        .transition(.opacity.animation(.easeInOut))
                }
                // << ------------------------- >>
                
                Spacer()

                // --- Bagian Status dan Hasil ---
                if isAnalyzing {
                    VStack {
                        ProgressView("Menganalisis video...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Pastikan wajah terlihat jelas di frame debug di atas.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }.padding()
                } else if let finalScore = score {
                    VStack {
                        Text("Ini Skor Kontak Mata Lu Bro")
                            .font(.headline)
                        Text(String(format: "%.1f%%", finalScore))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        Text("Persentase lu liat ke arah layar ini")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    // Tampilan awal
                    Image(systemName: "eye.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray.opacity(0.3))
                }

                Spacer()
                
                // --- Informasi File Video ---
                if let url = videoURL {
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal)
                }

                // --- Bagian Tombol Aksi ---
                VStack(spacing: 15) {
                    Button {
                        resetState() // Reset jika user memilih video baru
                        showingPicker = true
                    } label: {
                        Label("1. Pilih Video", systemImage: "video.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button {
                        startAnalysis()
                    } label: {
                        Label("2. Mulai Analisis", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(videoURL == nil || isAnalyzing)
                }
                
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPicker) {
                VideoPicker(videoURL: $videoURL)
            }
            .alert("Informasi", isPresented: .constant(errorAlertMessage != nil), actions: {
                Button("OK") { errorAlertMessage = nil }
            }, message: {
                Text(errorAlertMessage ?? "Terjadi kesalahan tidak diketahui.")
            })
        }
        .animation(.default, value: isAnalyzing)
        .animation(.default, value: score)
    }

    // MARK: - Logic Functions
    
    // --- FUNGSI UTAMA YANG DIPERBAIKI ---
    private func startAnalysis() {
        guard let url = videoURL else {
            errorAlertMessage = "Silakan pilih video terlebih dahulu."
            return
        }
        
        isAnalyzing = true
        score = nil
        currentFrameForDebug = nil // Bersihkan frame lama
        
//        // Test face detection on the first frame for debugging
//        extractFrames(from: url, fps: 1) { framesWithOrientation in
//            if let firstFrame = framesWithOrientation.first {
//                self.testFaceDetection(image: firstFrame.image)
//            }
//        }
        
        // Panggil fungsi `calculatePublicSpeakingScore` dengan parameter `onFrameProcessed`
        calculatePublicSpeakingScore(
            from: url,
            onFrameProcessed: { frame in
                // Callback ini akan dipanggil untuk setiap frame yang dianalisis.
                // Kita menggunakannya untuk memperbarui UI debug.
                self.currentFrameForDebug = frame
            },
            completion: { calculatedScore in
                // Callback ini dipanggil setelah semua frame selesai dianalisis.
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    self.currentFrameForDebug = nil // Sembunyikan frame debug setelah selesai
                        
                    if calculatedScore == 0.0 && self.videoURL != nil {
                        self.errorAlertMessage = "Analisis selesai. Skor Anda 0%. Ini bisa berarti tidak ada wajah yang terdeteksi, atau Anda selalu melihat ke samping. Pastikan wajah terlihat jelas dalam video."
                    }
                    self.score = calculatedScore
                }
            }
        )
    }
    
    private func resetState() {
        videoURL = nil
        score = nil
        currentFrameForDebug = nil
        isAnalyzing = false
    }
    
    // --- FUNGSI UNTUK TEST FACE DETECTION ---
    private func testFaceDetection(image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("DEBUG: Failed to convert UIImage to CGImage for test")
            return
        }
        let request = VNDetectFaceLandmarksRequest { (request, error) in
            if let error = error {
                print("DEBUG: Vision request failed: \(error)")
                return
            }
            if let observations = request.results as? [VNFaceObservation], !observations.isEmpty {
                print("DEBUG: Detected \(observations.count) face(s) in test frame")
                for (index, face) in observations.enumerated() {
                    print("DEBUG: Face \(index + 1):")
                    print("DEBUG:   Bounding box: \(face.boundingBox)")
                    print("DEBUG:   Yaw: \(face.yaw?.doubleValue ?? 0)")
                    print("DEBUG:   Pitch: \(face.pitch?.doubleValue ?? 0)")
                    if let landmarks = face.landmarks {
                        print("DEBUG:   Left pupil points: \(landmarks.leftPupil?.pointCount ?? 0)")
                        print("DEBUG:   Left eye points: \(landmarks.leftEye?.pointCount ?? 0)")
                    }
                }
            } else {
                print("DEBUG: No faces detected in test frame")
            }
        }
        request.revision = VNDetectFaceLandmarksRequestRevision3 // Use latest revision
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("DEBUG: Failed to perform Vision request: \(error)")
        }
    }
}

// MARK: - Video Picker (Wrapper untuk PHPickerViewController) - VERSI PERBAIKAN
struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
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
        var parent: VideoPicker
        init(_ parent: VideoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else { return }

            // --- PERBAIKAN UTAMA: Gunakan loadFileRepresentation ---
            // Ini adalah cara yang jauh lebih andal untuk menangani file video.
            if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { (url, error) in
                    if let error = error {
                        print("ERROR: Gagal memuat file representasi video: \(error)")
                        return
                    }
                    
                    guard let sourceURL = url else {
                        print("ERROR: URL sumber dari loadFileRepresentation adalah nil.")
                        return
                    }
                    
                    // Buat nama file tujuan yang unik untuk menghindari konflik.
                    let fileName = UUID().uuidString + ".mov"
                    let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    
                    do {
                        // Hapus file lama jika ada.
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        
                        // Salin file dari URL sumber sementara ke direktori tujuan aplikasi kita.
                        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                        
                        // Update UI di main thread
                        DispatchQueue.main.async {
                            print("SUCCESS: Video berhasil disalin ke \(destinationURL.path)")
                            self.parent.videoURL = destinationURL
                        }
                        
                    } catch {
                        print("ERROR: Gagal menyalin video ke direktori sementara: \(error)")
                    }
                }
            }
        }
    }
}

struct EyeContactAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        EyeContactAnalysisView()
    }
}
