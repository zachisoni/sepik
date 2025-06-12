import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Top illustration
            ZStack {
                // Split background: top half primary, bottom half white
                VStack(spacing: 0) {
                    Color("AccentPrimary")
                    Color("AccentColor")
                }
                .ignoresSafeArea()
                
                Image("person")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
            }

            // Input section
            VStack(spacing: 24) {
                // Multi-colored title
                (Text("What's ")
                    .foregroundColor(Color("AccentPrimary"))
                    .font(.title)
                    .fontWeight(.bold)
                + Text("your name,")
                    .foregroundColor(Color("AccentSecondary"))
                    .font(.title)
                    .fontWeight(.bold)
                + Text(" you little performer?")
                    .foregroundColor(Color("AccentPrimary"))
                    .font(.title)
                    .fontWeight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                TextField("Your name", text: $viewModel.userName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                NavigationLink(destination: VideoInputView()) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canProceed ? Color("AccentPrimary") : Color("AccentDisabled"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!viewModel.canProceed)
                .padding(.horizontal)
            }
            .padding(.top, -50)

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
} 
