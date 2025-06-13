import SwiftUI

struct InputNameView: View {
    @StateObject private var viewModel = InputNameViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Top illustration with split background
            ZStack {
                // Split background: equal halves within the container
                VStack(spacing: 0) {
                    Color("AccentPrimary")
                    Color("AccentColor")
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Image("person")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                    Spacer()
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.6)

            // Input section - positioned higher
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

                // Custom text field with white background
                ZStack(alignment: .leading) {
                    if viewModel.userName.isEmpty {
                        Text("Raissa")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextField("", text: $viewModel.userName)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)

                NavigationLink(destination: TabContainerView()) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canProceed ? Color("AccentPrimary") : Color("AccentDisabled"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!viewModel.canProceed)
                .padding(.horizontal)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.saveUserName()
                })
            }
            .padding(.top, 20)

            Spacer()
        }
        .background(Color("AccentColor"))
        .preferredColorScheme(.light)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

struct InputNameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            InputNameView()
        }
    }
} 