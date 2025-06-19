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
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor(named: "AccentPrimary")
        appearance.shadowColor = nil
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.1))
        .tint(.white)
        .photosPicker(
            isPresented: $viewModel.isPickerPresented,
            selection: $viewModel.selectedItem,
            matching: .videos,
            preferredItemEncoding: .current
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
    
    private var backgroundView: some View {
        VStack(spacing: 0) {
            Color("AccentPrimary")
                .frame(height: UIScreen.main.bounds.height * 0.4)
            Color.white
        }
        .ignoresSafeArea()
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Record, input and analyze\nyour rehearsal video.")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                
                // Recording Requirements Card
                VStack(alignment: .leading, spacing: 24) {
                    Text("Recording Requirements")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

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
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                .padding(.bottom, 24)

                // Video Upload and Analysis Section
                VStack(spacing: 16) {
                    if let videoURL = viewModel.selectedVideo {
                        ZStack(alignment: .topTrailing) {
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: 200)
                                .cornerRadius(10)
                            
                            // Delete button overlay
                            Button(action: {
                                viewModel.deleteVideo()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                        .padding(.horizontal)
                    } else {
                        DashedUploadBox()
                            .padding(.horizontal)
                            .onTapGesture { viewModel.isPickerPresented = true }
                    }

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
                .padding(.bottom, 100) // Space for tab bar
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

            Text("Supported format: .MOV (Max duration 5 minutes)")
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

