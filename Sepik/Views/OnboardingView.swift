import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var inputNameViewModel = InputNameViewModel()
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()

            TabView(selection: $viewModel.currentPage) {
                // Slide 1 & 2
                ForEach(viewModel.pages.indices, id: \.self) { index in
                    let page = viewModel.pages[index]
                    VStack(spacing: 0) {
                        ZStack {
                            Image(page.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.55)
                                .clipped()
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.55)

                        VStack(spacing: 24) {
                            // Title
                            titleForSlide(index: index)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            // Page indicators
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { dotIndex in
                                    Circle()
                                        .fill(dotIndex == index ? Color("AccentSecondary") : Color("AccentSecondary").opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.top, 8)

                            Text(page.description)
                                .font(.body)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                    .tag(index)
                }

                // Slide 3 - Input Name (Using working keyboard avoidance structure)
                ZStack(alignment: .top) {
                    // Scrollable content
                    ScrollViewReader { proxy in
                        ScrollView {
                            ZStack {
                                VStack(spacing: 0) {
                                    Color("AccentPrimary")
                                        .frame(height: UIScreen.main.bounds.height * 0.55)
                                    Color("AccentColor")
                                }
                                
                                VStack(spacing: 0) {
                                    // Image section - positioned same as slides 1 & 2
                                    VStack {
                                        Spacer()
                                        Image("person")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 280)
                                        Spacer()
                                    }
                                    .frame(height: UIScreen.main.bounds.height * 0.55)
                                    
                                    // Content section - matching slides 1 & 2 structure
                                    VStack(spacing: 24) {
                                        // Title - positioned same as slides 1 & 2
                                        slide3Title()
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        
                                        // Page indicators - positioned same as slides 1 & 2
                                        HStack(spacing: 8) {
                                            ForEach(0..<3, id: \.self) { dotIndex in
                                                Circle()
                                                    .fill(dotIndex == 2 ? Color("AccentSecondary") : Color("AccentSecondary").opacity(0.3))
                                                    .frame(width: 8, height: 8)
                                            }
                                        }
                                        .padding(.top, 8)
                                        
                                        // Input field - positioned where description would be in slides 1 & 2
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
                                                .focused($isNameFieldFocused)
                                        }
                                        .padding(.horizontal)
                                        .id("NameFieldSection")
                                        
                                        // Button positioned right below input field, aligned with description area
                                        NavigationLink(destination: TabContainerView(initialTab: 0)) {
                                            Text("Get Started!")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(inputNameViewModel.canProceed ? Color("AccentPrimary") : Color("AccentDisabled"))
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .disabled(!inputNameViewModel.canProceed)
                                        .padding(.horizontal)
                                        .simultaneousGesture(TapGesture().onEnded {
                                            inputNameViewModel.saveUserName()
                                        })
                                    }
                                    .padding(.vertical, 20)
                                    
                                    Spacer()
                                }
                                .padding(.bottom, keyboardHeight) // push up by keyboard height
                                .onChange(of: isNameFieldFocused) { oldValue, newValue in
                                    if newValue {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            withAnimation {
                                                proxy.scrollTo("NameFieldSection", anchor: .center)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .tag(2)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notif in
            if let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation {
                    self.keyboardHeight = frame.height - 20 // adjust if needed
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation {
                self.keyboardHeight = 0
            }
        }
    }
    
    // Helper function to simplify slide titles
    private func titleForSlide(index: Int) -> Text {
        if index == 0 {
            return Text("Elevate ")
                .foregroundColor(Color("AccentSecondary"))
                .font(.title)
                .fontWeight(.bold)
            + Text("your public speaking performance")
                .foregroundColor(Color("AccentPrimary"))
                .font(.title)
                .fontWeight(.bold)
        } else {
            return Text("Get feedback on ")
                .foregroundColor(Color("AccentSecondary"))
                .font(.title)
                .fontWeight(.bold)
            + Text("your facial expressions")
                .foregroundColor(Color("AccentPrimary"))
                .font(.title)
                .fontWeight(.bold)
        }
    }
    
    // Helper function for slide 3 title
    private func slide3Title() -> Text {
        return Text("What's ")
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
            .fontWeight(.bold)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView()
        }
    }
}
