import SwiftUI

struct VideoInputView: View {
    @StateObject private var viewModel = VideoInputViewModel()
    @State private var showPicker = false

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Recording Requirements")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)

                    RequirementView(
                        imageName: "rules1",
                        title: "Face exposed in the video",
                        description: "Make sure your face is clearly visible in the frame."
                    )

                    RequirementView(
                        imageName: "rules2",
                        title: "No crowded/fare situation",
                        description: "Avoid recording in crowded or noisy environments."
                    )

                    RequirementView(
                        imageName: "rules3",
                        title: "Natural/normal lighting",
                        description: "Ensure good lighting so your expressions are captured correctly."
                    )

                    VStack(spacing: 16) {
                        Button(action: { showPicker = true }) {
                            HStack {
                                Image(systemName: "video")
                                Text("Choose Files")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentPrimary"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showPicker) {
                            VideoPicker(videoURL: $viewModel.videoURL)
                        }

                        Text("Supported format: .MOV (Max size 5 gb)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)

                        NavigationLink {
                            if let url = viewModel.videoURL {
                                LoadingView(videoURL: url)
                            }
                        } label: {
                            Text("Start Analysis")
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RequirementView: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Color("AccentSecondary")
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
}

struct VideoInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VideoInputView()
        }
    }
} 