import SwiftUI
import SwiftData

struct LoadingView: View {
    @StateObject private var viewModel: AnalysisViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var navigate = false
    @State private var animationAmount = 1.0
    private let videoURL: URL

    init(videoURL: URL) {
        self.videoURL = videoURL
        _viewModel = StateObject(wrappedValue: AnalysisViewModel(videoURL: videoURL))
    }

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                Image("microphone")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .scaleEffect(animationAmount)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            animationAmount = 1.2
                        }
                    }
                
                if viewModel.isProcessing {
                    VStack(spacing: 16) {
                        Text("We're processing your rehearsal right away!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AccentPrimary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Progress indicator
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.analysisProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color("AccentSecondary")))
                                .frame(height: 8)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(4)
                                .padding(.horizontal, 40)
                            
                            Text(viewModel.currentStep)
                                .font(.body)
                                .foregroundColor(.accentPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("\(Int(viewModel.analysisProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.accentSecondary)
                        }
                    }
                }
                Spacer()
            }
        }
        .preferredColorScheme(.light)
        .navigationDestination(isPresented: $navigate) {
            if let result = viewModel.result {
                ResultView(result: result, isFromAnalysis: true, videoURL: videoURL)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Configure the view model with model context
            viewModel.dataManager = DataManager(modelContext: modelContext)
        }
        .task {
            await viewModel.analyze()
            if viewModel.result != nil {
                navigate = true
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoadingView(videoURL: URL(string: "file://dummy.mov")!)
        }
        .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
    }
} 
