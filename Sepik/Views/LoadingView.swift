import SwiftUI
import SwiftData

internal struct LoadingView: View {
    @StateObject private var viewModel: AnalysisViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var navigate = false
    @State private var showError = false
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

                // New frame animation - tied to processing state
                FrameAnimationView(isActive: viewModel.isProcessing || viewModel.result == nil)
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
                } else if let errorMessage = viewModel.errorMessage {
                    // Show error state when analysis fails
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)

                        Text("Analysis Failed")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AccentPrimary"))

                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(Color("AccentPrimary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            Task {
                                await retryAnalysis()
                            }
                        }, label: {
                            Text("Retry")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color("AccentPrimary"))
                                .cornerRadius(8)
                        })
                    }
                } else if !viewModel.isProcessing && viewModel.result == nil && viewModel.errorMessage == nil {
                    // Show waiting state if not processing but no result or error
                    VStack(spacing: 16) {
                        Text("Preparing analysis...")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AccentPrimary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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
            await startAnalysis()
        }
        .onChange(of: viewModel.result) {
            if viewModel.result != nil {
                navigate = true
            }
        }
    }

    private func startAnalysis() async {
        await viewModel.analyze()
    }

    private func retryAnalysis() async {
        viewModel.errorMessage = nil
        viewModel.analysisProgress = 0.0
        viewModel.currentStep = ""
        await viewModel.analyze()
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoadingView(videoURL: URL(string: "file://dummy.mov") ?? URL(fileURLWithPath: "/dev/null"))
        }
        .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
    }
}
