import SwiftUI
import SwiftData

struct LoadingView: View {
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
                FrameAnimationView()
                    .frame(width: 400)
                    .offset(x: 20)
                    .scaleEffect(1.4)
                if viewModel.isProcessing {
                    Gauge(value: viewModel.analysisProgress){
                        Text("We're processing your rehearsal right away!")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("AccentPrimary"))
                            .multilineTextAlignment(.center)
                        
                    }
                    .gaugeStyle(.linearCapacity)
                    .tint(Color("AccentSecondary"))
                    .padding(.horizontal, 32)
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
            LoadingView(videoURL:URL(string: "file://dummy.mov")!)
        }
        .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
    }
}
