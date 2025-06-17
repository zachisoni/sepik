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
            VStack(spacing: 0) {
                Color("AccentPrimary")
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                Color.white
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text("Record, input and analyze your rehearsal video.")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    VStack(alignment: .leading, spacing: 24){
                        Text("Recording Guides")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        RecordingRequirementRow(
                            title: "Face exposed in the video",
                            description: "Ensure that your face is fully visible and centered within the camera frame",
                            image: "rules1"
                        )

                        RecordingRequirementRow(
                            title: "No crowded/fare situation",
                            description: "Choose a quiet place away from crowds or public activity before recording",
                            image: "rules2"
                        )

                        RecordingRequirementRow(
                            title: "Natural/normal lighting",
                            description: "For clear video, use soft, natural lighting and avoid dark or overly bright settings",
                            image: "rules3"
                        )
                    }.frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.5), lineWidth: 0.5)
                        )

                    VStack(spacing: 16) {
                        if let videoURL = viewModel.selectedVideo {
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .frame(height: 200)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        } else {
                            DashedUploadBox()
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

                    }
                }
                .padding(.vertical)
            }.padding(.horizontal).safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
            .scrollIndicators(.hidden)
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
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Audio session error: \(error.localizedDescription)")
            }
            
            let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(named: "AccentPrimary") // Pastikan warnanya gelap agar putih kontras
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            appearance.shadowColor = .clear
                appearance.backgroundEffect = nil
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Color("AccentSecondary")
                    .frame(width: 75, height: 75)
                    .cornerRadius(8)
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                    .foregroundColor(.black)
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
//        .padding(.horizontal)
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
