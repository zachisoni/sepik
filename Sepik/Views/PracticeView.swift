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
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Back Button
                    HStack {
                        NavigationLink(destination: InputNameView()) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(Color("AccentPrimary"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Text("Recording Requirements")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    RecordingRequirementRow(
                        title: "Face exposed in the video",
                        description: "Make sure your face is clearly visible in the frame.",
                        image: "rules1"
                    )

                    RecordingRequirementRow(
                        title: "No crowded/fare situation",
                        description: "Avoid recording in crowded or noisy environments.",
                        image: "rules2"
                    )

                    RecordingRequirementRow(
                        title: "Natural/normal lighting",
                        description: "Ensure good lighting so your expressions are captured correctly.",
                        image: "rules3"
                    )

                    VStack(spacing: 16) {
                        if let videoURL = viewModel.selectedVideo {
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: 200)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        } else {
                            DashedUploadBox()
                                .padding(.horizontal)
                                .onTapGesture { viewModel.isPickerPresented = true }
                        }

                        Text("Supported format: .MOV (Max size 5 gb)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)

                        NavigationLink {
                            if let url = viewModel.selectedVideo {
                                LoadingView(videoURL: url)
                            }
                        } label: {
                            Text(viewModel.isLoading ? "Processing..." : "Start Analysis")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.canProceed ? Color("AccentPrimary") : Color("AccentDisabled"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(!viewModel.canProceed)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
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
        .navigationBarBackButtonHidden(true)
        .onAppear {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Audio session error: \(error.localizedDescription)")
            }
        }
    }
}

struct DashedUploadBox: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8){
                Image(systemName: "video")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("Choose Files")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 32)
            .background(Color("AccentPrimary"))
            .cornerRadius(8)

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
            ZStack {
                Color("AccentSecondary")
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
}

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PracticeView()
        }
    }
}

