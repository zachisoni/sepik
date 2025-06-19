import SwiftUI
import SwiftData

internal struct LoadingView: View {
    @StateObject private var viewModel: AnalysisViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var navigate = false
    @State private var animationAmount = 1.0
    private let videoURL: URL?

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
                
                // New frame animation from incoming branch
                FrameAnimationView()
                    .frame(width: 400)
                    .offset(x: 20)
                    .scaleEffect(1.4)
                
                if viewModel.isProcessing {
                    VStack(spacing: 16) {
                        Text("We're processing your rehearsal right away!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AccentPrimary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Enhanced progress indicator with both styles
                        VStack(spacing: 12) {
                            // Modern Gauge style from incoming branch
                            Gauge(value: viewModel.analysisProgress) {
                                Text("Analysis Progress")
                                    .font(.caption)
                                    .foregroundColor(.accentPrimary)
                            }
                            .gaugeStyle(.linearCapacity)
                            .tint(Color("AccentSecondary"))
                            .padding(.horizontal, 32)
                            
                            // Detailed progress information from current branch
                            VStack(spacing: 8) {
                                Text(viewModel.currentStep)
                                    .font(.body)
                                    .foregroundColor(.accentPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Text("\(Int(viewModel.analysisProgress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.accentSecondary)
                                    .fontWeight(.semibold)
                            }
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
