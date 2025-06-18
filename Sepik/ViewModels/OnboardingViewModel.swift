import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Elevate your public speaking performance",
            description: "Observe the detailed analysis of your public speaking performance.",
            imageName: "onboarding1"
        ),
        OnboardingPage(
            title: "Get feedback on your facial expressions",
            description: "See when you smile, blink, or look distracted during your practice.",
            imageName: "onboarding2"
        )
    ]
} 