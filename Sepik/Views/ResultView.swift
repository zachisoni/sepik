import SwiftUI
import AVKit

struct ResultView: View {
    let result: AnalysisResult
    let sessionDate: Date?
    let isFromAnalysis: Bool
    let videoURL: URL?
    private let userManager = UserManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(result: AnalysisResult, sessionDate: Date? = nil, isFromAnalysis: Bool = false, videoURL: URL? = nil) {
        self.result = result
        self.sessionDate = sessionDate
        self.isFromAnalysis = isFromAnalysis
        self.videoURL = videoURL
        
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
        result.fillerCounts.count
    }
    
    private var mostFrequentFillerWord: String {
        // Get the most frequent filler word regardless of frequency
        return result.fillerCounts.max(by: { $0.value < $1.value })?.key ?? "uh"
    }
    
    private var fillerWordsDescription: String {
        if totalFillerWords == 0 {
            return "Great job! You didn't use any filler words. Keep up the excellent speaking pace."
        } else {
            let fillerWordsList = result.fillerCounts.compactMap { (word, count) in
                count > 0 ? "\(word) (\(count)x)" : nil
            }.joined(separator: ", ")
            
            if totalFillerWords <= 3 {
                return "You used minimal filler words: \(fillerWordsList). This shows good control!"
            } else {
                return "Detected filler words: \(fillerWordsList). Try practicing with short pauses instead of these repetitive words."
            }
        }
    }
    
    private var smilePercentage: Double {
        let total = result.smileFrames + result.neutralFrames
        return total > 0 ? Double(result.smileFrames) / Double(total) * 100 : 0
    }
    
    private var expressionQuality: String {
        let smilePct = smilePercentage / 100.0
        switch smilePct {
        case 0.3...: return "Good Expressions"
        case 0.15..<0.3: return "Flat Expressions"
        default: return "Bad Expressions"
        }
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
    
    private var eyeContactQuality: String {
        guard let score = result.eyeContactScore else { return "Eye Contact" }
        switch score {
        case 60...70: return "Excellent Eye Contact"
        case 40..<60, 71...80: return "Moderate Eye Contact"
        default: return "Poor Eye Contact"
        }
    }
    
    private func eyeContactColor() -> Color {
        guard let score = result.eyeContactScore else { return .purple }
        switch score {
        case 60...70: return .green
        case 40..<60, 71...80: return .orange
        default: return .red
        }
    }
    
    private func eyeContactDescription() -> String {
        guard let score = result.eyeContactScore else { 
            return "Eye contact analysis will be available in future updates."
        }
        switch score {
        case 60...70:
            return "Perfect! You maintained excellent eye contact at the ideal level."
        case 40..<60:
            return "Good, but try to maintain more consistent eye contact with your audience."
        case 71...80:
            return "Good, but try to vary your gaze occasionally to appear more natural."
        case 81...:
            return "You're looking too intensely. Try to blink and look away occasionally for a more natural delivery."
        default:
            return "Focus on maintaining more eye contact with your audience to build connection and trust."
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
                        .padding(.bottom, 8)
                }
                .padding(.top, 8)
                // Video Player
                if let url = videoURL ?? result.videoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }
                HStack {
                    Text(expressionQuality == "Good Expressions" ? "Confident" : "Needs Work")
                        .font(.footnote)
                        .frame(minHeight: 30)
                        .fontWeight(.regular)
                        .foregroundColor(expressionQuality == "Good Expressions" ? .green : .orange)
                        .padding(.horizontal, 32)
                        .background((expressionQuality == "Good Expressions" ? Color.green : Color.orange).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(expressionQuality == "Good Expressions" ? .green : .orange, lineWidth: 2)
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
                            // Expression Indicator
                            IndicatorCard(
                                icon: "indicator1",
                                iconColor: expressionColor(),
                                title: expressionQuality,
                                value: String(format: "%.1f%%", smilePercentage),
                                description: expressionDescription()
                            )
                            
                            // Filler Words Indicator
                            IndicatorCard(
                                icon: "indicator2",
                                iconColor: .orange,
                                title: "Filler Words",
                                value: "\(totalFillerWords) words",
                                description: fillerWordsDescription
                            )
                            
                            // Speaking Pace Indicator
                            IndicatorCard(
                                icon: "indicator3",
                                iconColor: paceColor(),
                                title: paceCategory,
                                value: "\(Int(result.wpm)) wpm",
                                description: paceDescription
                            )
                            // Eye Contact Indicator
                            IndicatorCard(
                                icon: "indicator4",
                                iconColor: eyeContactColor(),
                                title: eyeContactQuality,
                                value: result.eyeContactScore != nil ? String(format: "%.1f%%", result.eyeContactScore ?? "0.0%") : "Coming Soon",
                                description: eyeContactDescription()
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
                // Fixed Buttons
                HStack(spacing: 16) {
                    if isFromAnalysis {
                        NavigationLink(destination: TabContainerView(initialTab: 1)) {
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
                        
                        NavigationLink(destination: TabContainerView(initialTab: 0)) {
                            Text("Restart analysis")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentPrimary"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Back to History")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentPrimary"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(Color.white)
            }
        }
        .navigationBarBackButtonHidden(!isFromAnalysis)
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
    
    private func expressionIcon() -> String {
        switch expressionQuality {
        case "Good Expressions": return "face.smiling"
        case "Flat Expressions": return "face.dashed"
        default: return "face.dashed"
        }
    }
    
    private func expressionColor() -> Color {
        switch expressionQuality {
        case "Good Expressions": return .green
        case "Flat Expressions": return .orange
        default: return .red
        }
    }
    
    private func expressionDescription() -> String {
        switch expressionQuality {
        case "Good Expressions":
            return "Great job! Keep smiling to engage your audience."
        case "Flat Expressions":
            return "Try to smile more often to appear more engaging and confident."
        default:
            return "You need to smile much more to appear engaging and confident."
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
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.callout)
                        .foregroundColor(.black)
                        .lineLimit(1)
                }
                
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
                    fillerCounts: ["uh": 5, "like": 3],
                    videoURL: URL(string: "https://example.com/video.mp4"),
                    eyeContactScore: 65.0
                ),
                sessionDate: Date(),
                isFromAnalysis: true,
                videoURL: URL(string: "https://example.com/video.mp4")
            )
        }
        .modelContainer(for: PracticeSession.self)
    }
}
