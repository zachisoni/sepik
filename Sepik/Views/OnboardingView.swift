import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var inputNameViewModel = InputNameViewModel()

    var body: some View {
        ZStack {
            // Full AccentColor background
            Color("AccentColor")
                .ignoresSafeArea()
            
            TabView(selection: $viewModel.currentPage) {
                // Slide 1 & 2: Full-screen transparent images with overlaid content
                ForEach(viewModel.pages.indices, id: \.self) { index in
                    let page = viewModel.pages[index]
                    
                    ZStack {
                        // Full-screen transparent image overlay
                        Image(page.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .clipped()
                            .ignoresSafeArea(.all)
                        
                        // Content overlay positioned consistently for slides 1 and 2
                        VStack(spacing: 32) {
                            Spacer()
                            
                            // Content section aligned for slides 1 and 2
                            VStack(spacing: 24) {
                                // Title
                                Group {
                                    if index == 0 {
                                        Text("Elevate ")
                                            .foregroundColor(Color("AccentSecondary"))
                                            .font(.title)
                                            .fontWeight(.bold)
                                        + Text("your public speaking performance")
                                            .foregroundColor(Color("AccentPrimary"))
                                            .font(.title)
                                            .fontWeight(.bold)
                                    } else {
                                        Text("Get feedback on ")
                                            .foregroundColor(Color("AccentSecondary"))
                                            .font(.title)
                                            .fontWeight(.bold)
                                        + Text("your facial expressions")
                                            .foregroundColor(Color("AccentPrimary"))
                                            .font(.title)
                                            .fontWeight(.bold)
                                    }
                                }
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                
                                // Custom page indicators
                                HStack(spacing: 8) {
                                    ForEach(0..<3, id: \.self) { dotIndex in
                                        Circle()
                                            .fill(dotIndex == index ? Color("AccentSecondary") : Color("AccentSecondary").opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                
                                // Description
                                Text(page.description)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            Spacer()
                                .frame(height: 80) // Fixed bottom spacing
                        }
                    }
                    .tag(index)
                }
                
                // Slide 3: Input Name View with full-screen transparent image
                ZStack {
                    // Full-screen transparent image overlay
                    Image("onboarding3")
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                        .ignoresSafeArea(.all)
                    
                    // Content overlay positioned lower on the screen
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(minHeight: UIScreen.main.bounds.height * 0.5) // Push content to bottom half
                        
                        // Content section positioned lower
                        VStack(spacing: 14) {
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
                            .padding(.horizontal, 20)
                            
                            // Custom page indicators
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { dotIndex in
                                    Circle()
                                        .fill(dotIndex == 2 ? Color("AccentSecondary") : Color("AccentSecondary").opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }

                            // Custom text field with white background
                            ZStack(alignment: .leading) {
                                if inputNameViewModel.userName.isEmpty {
                                    Text("Raissa")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                
                                TextField("", text: $inputNameViewModel.userName)
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
                            .padding(.horizontal, 20)

                            NavigationLink(destination: TabContainerView(initialTab: 0)) {
                                Text("Get Started!")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(inputNameViewModel.canProceed ? Color("AccentPrimary") : Color("AccentDisabled"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .disabled(!inputNameViewModel.canProceed)
                            .padding(.horizontal, 20)
                            .simultaneousGesture(TapGesture().onEnded {
                                inputNameViewModel.saveUserName()
                            })
                        }
                        
                        Spacer()
                            .frame(height: 80) // Fixed bottom spacing
                    }
                }
                .tag(2)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView()
        }
    }
} 
