import SwiftUI
import SwiftData

struct LoadingView: View {
    @StateObject private var viewModel: AnalysisViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var navigate = false

    init(videoURL: URL) {
        _viewModel = StateObject(wrappedValue: AnalysisViewModel(videoURL: videoURL))
    }

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Image("barchart")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                if viewModel.isProcessing {
                    Text("We're processing your rehearsal right away!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
        .preferredColorScheme(.light)
        .navigationDestination(isPresented: $navigate) {
            if let result = viewModel.result {
                ResultView(result: result)
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