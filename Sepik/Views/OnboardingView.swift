import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var inputNameViewModel = InputNameViewModel()
    @State private var keyboardHeight: CGFloat = 0

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
                
                // Slide 3: Input Name View with full-screen transparent image and keyboard handling
                ZStack {
                    // Full-screen transparent image overlay
                    Image("onboarding3")
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                        .ignoresSafeArea(.all)
                    
                    // Content overlay with keyboard avoidance
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 0) {
                                // Dynamic spacer that adjusts for keyboard
                                Spacer()
                                    .frame(height: keyboardHeight > 0 ? 
                                           max(50, geometry.size.height - keyboardHeight - 300) : // Position above keyboard
                                           geometry.size.height * 0.65) // Original lower position when no keyboard
                                
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
                                    
                                    // Custom page indicators - hidden when keyboard is active
                                    if keyboardHeight == 0 {
                                        HStack(spacing: 8) {
                                            ForEach(0..<3, id: \.self) { dotIndex in
                                                Circle()
                                                    .fill(dotIndex == 2 ? Color("AccentSecondary") : Color("AccentSecondary").opacity(0.3))
                                                    .frame(width: 8, height: 8)
                                            }
                                        }
                                        .transition(.opacity)
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
                                .padding(.vertical, keyboardHeight > 0 ? 24 : 0) // Add padding when keyboard is active
                                .background(
                                    // Card background when keyboard is active
                                    keyboardHeight > 0 ? 
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color("AccentColor"))
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    : nil
                                )
                                .padding(.horizontal, keyboardHeight > 0 ? 16 : 0) // Add horizontal padding for card effect
                                
                                // Bottom spacer to ensure content can scroll above keyboard
                                Spacer()
                                    .frame(height: keyboardHeight > 0 ? keyboardHeight + 50 : 80)
                            }
                        }
                        .scrollDisabled(keyboardHeight == 0) // Only allow scrolling when keyboard is shown
                        .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
                    }
                }
                .tag(2)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onChange(of: viewModel.currentPage) {
            // Dismiss keyboard when swiping to different slides
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView()
        }
    }
} 
