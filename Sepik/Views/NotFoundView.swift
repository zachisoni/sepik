import SwiftUI

struct NotFoundView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Full AccentColor background
            Color("AccentColor")
                .ignoresSafeArea()
            
            // Full-screen image overlay
            Image("notfound")
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .clipped()
                .ignoresSafeArea(.all)
            
            // Content overlay
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                
                // Content section
                VStack(spacing: 24) {
                    // Multi-colored title
                    (Text("You're not in the video ")
                        .foregroundColor(Color("AccentPrimary"))
                        .font(.title)
                        .fontWeight(.bold)
                    + Text("🫣")
                        .font(.title)
                    + Text(", try upload your video practice!")
                        .foregroundColor(Color("AccentSecondary"))
                        .font(.title)
                        .fontWeight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    
                    // Back button - navigate to TabContainerView (Practice view)
                    NavigationLink(destination: TabContainerView(initialTab: 0)) {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentPrimary"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                    .frame(height: 80)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct NotFoundView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotFoundView()
        }
    }
} 
