//
//  PracticeView.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import SwiftUI
import PhotosUI
import AVKit

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                contentSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 20)
                }
            .photosPicker(
                isPresented: $viewModel.isPickerPresented,
                selection: $viewModel.selectedItem,
                matching: .videos,
                preferredItemEncoding: .compatible
            )
            .onChange(of: viewModel.selectedItem) { oldItem, newItem in
                viewModel.onSelectedItemChanged(oldValue: oldItem, newValue: newItem)
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                    }
                }
            )
            .alert(item: Binding(
                get: { viewModel.errorMessage.map { ErrorMessage(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Audio session error: \(error.localizedDescription)")
            }
        }
    }

    private var contentSection: some View {
        VStack(spacing: 24) {
            requirementsSection
            videoSection
            startButton
        }
        .padding()
        .padding(.vertical, 16)
        .background(Color.white)
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recording Requirements")
                .frame(maxWidth: .infinity)
                .font(.title3)
                .bold()
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)

            RecordingRequirementRow(title: "Face exposed in the video", description: "Ensure the face is clearly visible in the entire video.", image: "rules1")
            RecordingRequirementRow(title: "No crowded/fare situation", description: "Record in a quiet environment without background distractions.", image: "rules2")
            RecordingRequirementRow(title: "Natural/normal lighting", description: "Ensure the video is recorded in well-lit conditions without artificial filters.", image: "rules3")
        }
    }

    private var videoSection: some View {
        Group {
            if let videoURL = viewModel.selectedVideo {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 200)
                    .cornerRadius(10)
            } else {
                DashedUploadBox()
                    .onTapGesture { viewModel.isPickerPresented = true }
            }
        }
    }

    private var startButton: some View {
        Button(action: {
            viewModel.startAnalysis()
        }) {
            Text(viewModel.isLoading ? "Processing..." : "Start Analysis")
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isVideoUploaded && !viewModel.isLoading ? Color.teal : Color(red: 175/255, green: 175/255, blue: 175/255))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(!viewModel.isVideoUploaded || viewModel.isLoading)
    }
}

struct DashedUploadBox: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8){
                Image(systemName: "film")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("Choose Files")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 32)
            .background(Color.teal)
            .cornerRadius(8)
            .shadow(color: Color(red: 28/255, green: 158/255, blue: 158/255), radius: 0.5, x: 0, y: 4)

            Text("Supported format: .MOV (Max size 5 gb)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundColor(.gray)
        )
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct RecordingRequirementRow: View {
    var title: String
    var description: String
    var image: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
//            Image(image)
//                .resizable()
//                .scaledToFit()
//                .frame(width: 65, height: 65)
//                .padding(16)
//                .background(.orange)
//                .cornerRadius(10)
            
            ZStack {
                Image(image)
                    .resizable()
                    .scaledToFit()
            }.frame(width: 60, height: 60)
                .padding(16)
                .background(.orange)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .bold()
                    .font(.callout)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeView()
    }
}

