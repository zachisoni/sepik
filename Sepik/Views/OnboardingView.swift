import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Color("AccentPrimary")
                Color("AccentColor")
            }
            .ignoresSafeArea()
            
            VStack {
                TabView(selection: $viewModel.currentPage) {
                    ForEach(viewModel.pages.indices, id: \.self) { index in
                        let page = viewModel.pages[index]
                        VStack(spacing: 20) {
                            Image(page.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                            
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
                                } else if index == 1 {
                                    Text("Get feedback on ")
                                        .foregroundColor(Color("AccentSecondary"))
                                        .font(.title)
                                        .fontWeight(.bold)
                                    + Text("your facial expressions")
                                        .foregroundColor(Color("AccentPrimary"))
                                        .font(.title)
                                        .fontWeight(.bold)
                                } else {
                                    Text("Track your ")
                                        .foregroundColor(Color("AccentSecondary"))
                                        .font(.title)
                                        .fontWeight(.bold)
                                    + Text("speaking pace and filler words")
                                        .foregroundColor(Color("AccentPrimary"))
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                            }
                            .multilineTextAlignment(.center)
                            
                            Text(page.description)
                                .font(.body)
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom, 40)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 500)
                .onAppear {
                    // Style page indicators with secondary color
                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color("AccentSecondary"))
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color("AccentSecondary")).withAlphaComponent(0.3)
                }

                if viewModel.currentPage == viewModel.pages.count - 1 {
                    NavigationLink(destination: HomeView()) {
                        Text("Get Started!")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentPrimary"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding()
                }
            }
        }
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
