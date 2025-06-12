import SwiftUI

struct LoadingView: View {
    @StateObject private var viewModel: AnalysisViewModel
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
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
        .navigationDestination(isPresented: $navigate) {
            if let result = viewModel.result {
                ResultView(result: result)
            }
        }
        .navigationBarBackButtonHidden(true)
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
    }
} 