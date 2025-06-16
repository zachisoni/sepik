import SwiftUI
import AVKit

struct ResultView: View {
    let result: AnalysisResult
    let sessionDate: Date?
    let videoURL: URL?
    private let userManager = UserManager.shared
    
    init(result: AnalysisResult, sessionDate: Date? = nil, videoURL: URL? = nil) {
        self.result = result
        self.sessionDate = sessionDate
        self.videoURL = videoURL
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.white
        ]
        appearance.backgroundColor = UIColor(named: "AccentPrimary")
        appearance.shadowColor = nil
        
        // Configure back button
        let backImage = UIImage(systemName: "chevron.backward")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backButtonAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: -10, vertical: 0)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
    
    // Computed properties for analysis
    private var totalFillerWords: Int {
        result.fillerCounts.values.reduce(0, +)
    }
    
    private var mostFrequentFillerWord: String {
        result.fillerCounts.max(by: { $0.value < $1.value })?.key ?? "none"
    }
    
    private var smilePerMinute: Double {
        let minutes = result.duration / 60.0
        return Double(result.smileFrames) / minutes
    }
    
    private var expressionQuality: String {
        let total = result.smileFrames + result.neutralFrames
        let smilePct = total > 0 ? Double(result.smileFrames) / Double(total) : 0
        return smilePct >= 0.3 ? "Good Expressions" : "Bad Expressions"
    }
    
    private var paceCategory: String {
        switch result.wpm {
        case ..<110: return "Slow"
        case 110...150: return "Targeted"
        default: return "Fast"
        }
    }
    
    private var paceDescription: String {
        switch result.wpm {
        case ..<110: return "You're speaking too slowly"
        case 110...150: return "Your pace is on target"
        default: return "You're speaking too fast"
        }
    }
    
    var body: some View {
        ZStack {
            // Split background
            VStack(spacing: 0) {
                Color("AccentPrimary")
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                Color.white
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("You're born for the stage, \(userManager.getUserName())! Keep it up!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                
                // Video Player
                if let url = videoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }
                
                HStack {
                    Text("Confident")
                        .font(.footnote)
                        .frame(minHeight: 30)
                        .fontWeight(.regular)
                        .foregroundColor(.green)
                        .padding(.horizontal, 32)
                        .background(Color.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.green, lineWidth: 2)
                        )
                        .cornerRadius(5)
                    
                    if let session = getSessionDate() {
                        Text("Result on \(session)")
                            .font(.callout)
                            .frame(maxWidth: .infinity, minHeight: 30)
                            .foregroundColor(.black)
                            .fontWeight(.regular)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Indicator Cards
                        VStack(spacing: 12) {
                            // Smile Indicator
                            IndicatorCard(
                                icon: "indicator1",
                                iconColor: .green,
                                title: "Smile",
                                value: "\(result.smileFrames)×",
                                description: "You smiled so well! Keep shining..."
                            )
                            
                            // Filler Words Indicator
                            IndicatorCard(
                                icon: "indicator2",
                                iconColor: .orange,
                                title: "Filler Words",
                                value: "\(totalFillerWords) words",
                                description: "There's no other words as imposters. Nice job!"
                            )
                            
                            // Speaking Pace Indicator
                            IndicatorCard(
                                icon: "indicator3",
                                iconColor: .blue,
                                title: "Speaking Pace",
                                value: "\(result.wpm) wpm", // Updated to show actual wpm
                                description: paceDescription
                            )
                            
                            // Eye Contact Indicator
                            IndicatorCard(
                                icon: "indicator4",
                                iconColor: .purple,
                                title: "Eye Contact",
                                value: "\(Int(result.eyeContactPercentage))%", // Updated to use eyeContactPercentage
                                description: "Great eye contact! Keep engaging your audience."
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
                
                // Fixed Buttons
                HStack(spacing: 16) {
                    NavigationLink(destination: HistoryView()) {
                        Text("Go to history")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(Color("AccentPrimary"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("AccentPrimary"), lineWidth: 2)
                            )
                            .cornerRadius(12)
                    }
                    NavigationLink(destination: TabContainerView()) {
                        Text("Restart analysis")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentPrimary"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(Color.white)
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationTitle("Analysis Result")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getSessionDate() -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy • h:mm"
        return formatter.string(from: sessionDate ?? Date())
    }
    
    private func paceIcon() -> String {
        switch result.wpm {
        case ..<110: return "tortoise"
        case 110...150: return "checkmark.circle"
        default: return "hare"
        }
    }
    
    private func paceColor() -> Color {
        switch result.wpm {
        case ..<110: return .blue
        case 110...150: return .green
        default: return .red
        }
    }
}

struct IndicatorCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(iconColor)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.callout)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(height: 100)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResultView(
                result: AnalysisResult(
                    duration: 1850,
                    smileFrames: 6,
                    neutralFrames: 8,
                    totalWords: 340,
                    wpm: 120,
                    fillerCounts: ["um": 2, "uh": 1]
                ),
                sessionDate: Date(),
                videoURL: URL(string: "https://example.com/video.mp4")
            )
        }
        .modelContainer(for: PracticeSession.self)
    }
}
