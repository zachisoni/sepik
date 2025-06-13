//
//  TabContainerView.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import AVKit

struct TabContainerView: View {
    @State private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            // Content based on selected tab
            Group {
                if selectedTab == 0 {
                    PracticeContentView()
                        .environment(\.modelContext, modelContext)
                } else {
                    HistoryView()
                        .environment(\.modelContext, modelContext)
                }
            }
            
            // Tab bar overlay
            VStack {
                Spacer()
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct PracticeContentView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
                .padding(.bottom, 100) // Add space for tab bar
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

#Preview {
    NavigationStack {
        TabContainerView()
    }
    .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
} 