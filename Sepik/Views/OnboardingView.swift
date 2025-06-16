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
                // Slide 1 & 2: Image slides
                ForEach(viewModel.pages.indices, id: \.self) { index in
                    let page = viewModel.pages[index]
                    
                    VStack(spacing: 0) {
                        // Top image section - full width and height extending to status bar
                        ZStack {
                            Image(page.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.55)
                                .clipped()
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.55)
                        .ignoresSafeArea(.all, edges: .top)
                        
                        // Content section
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
                        .padding(.horizontal)
                        
                        // Custom page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { dotIndex in
                                Circle()
                                    .fill(dotIndex == index ? Color("AccentSecondary") : Color("AccentSecondary").opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Description
                        Text(page.description)
                            .font(.body)
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                    .tag(index)
                }
                
                // Slide 3: Input Name View
                ZStack {
                    // Split background extending to status bar
                    VStack(spacing: 0) {
                        Color("AccentPrimary")
                            .frame(height: UIScreen.main.bounds.height * 0.5)
                        Color("AccentColor")
                    }
                    .ignoresSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        // Top illustration section
                        VStack {
                            Spacer()
                            Image("person")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                            Spacer()
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.5)

                        // Input section - positioned higher
                        VStack(spacing: 20) {
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
                            .padding(.horizontal)

                            NavigationLink(destination: TabContainerView()) {
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
                        .padding(.top, 30)

                        Spacer()
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
