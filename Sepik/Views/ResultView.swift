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
    
    // MARK: - New Scoring System
    
    private var smilePercentage: Double {
        let total = result.smileFrames + result.neutralFrames
        return total > 0 ? Double(result.smileFrames) / Double(total) * 100 : 0
    }
    
    private var totalFillerWords: Int {
        result.fillerCounts.values.reduce(0, +)
    }
    
    // Scoring functions based on new criteria
    private func smileScore() -> Int {
        let smilePct = smilePercentage
        if smilePct > 30 { return 2 }
        else if smilePct >= 15 { return 1 }
        else { return 0 }
    }
    
    private func fillerWordsScore() -> Int {
        if totalFillerWords <= 2 { return 2 }
        else if totalFillerWords <= 4 { return 1 }
        else { return 0 }
    }
    
    private func paceScore() -> Int {
        let wpm = result.wpm
        if wpm >= 110 && wpm <= 150 { return 2 }
        else if (wpm >= 90 && wpm <= 109) || (wpm >= 151 && wpm <= 170) { return 1 }
        else { return 0 }
    }
    
    private func eyeContactScore() -> Int {
        guard let eyeContact = result.eyeContactScore else { return 0 }
        if eyeContact >= 60 && eyeContact <= 70 { return 2 }
        else if (eyeContact >= 40 && eyeContact <= 59) || (eyeContact >= 71 && eyeContact <= 80) { return 1 }
        else { return 0 }
    }
    
    private var totalConfidenceScore: Int {
        return smileScore() + fillerWordsScore() + paceScore() + eyeContactScore()
    }
    
    private var confidenceLevel: String {
        let score = totalConfidenceScore
        if score >= 7 { return "Confident" }
        else if score >= 5 { return "Neutral" }
        else { return "Nervous" }
    }
    
    private var confidenceColor: Color {
        switch confidenceLevel {
        case "Confident": return .green
        case "Neutral": return .orange
        case "Nervous": return .red
        default: return .gray
        }
    }
    
    // MARK: - Updated evaluation methods
    
    private var expressionQuality: String {
        let score = smileScore()
        switch score {
        case 2: return "Excellent Expressions"
        case 1: return "Good Expressions"
        default: return "Poor Expressions"
        }
    }
    
    private var paceCategory: String {
        let score = paceScore()
        switch score {
        case 2: return "Perfect Pace"
        case 1: return "Acceptable Pace"
        default: return "Poor Pace"
        }
    }
    
    private var fillerWordsCategory: String {
        let score = fillerWordsScore()
        switch score {
        case 2: return "Excellent Control"
        case 1: return "Good Control"
        default: return "Poor Control"
        }
    }
    
    private var eyeContactQuality: String {
        guard result.eyeContactScore != nil else { return "Eye Contact" }
        let score = eyeContactScore()
        switch score {
        case 2: return "Perfect Eye Contact"
        case 1: return "Good Eye Contact"
        default: return "Poor Eye Contact"
        }
    }
    
    // MARK: - Description methods
    
    private var expressionDescription: String {
        let score = smileScore()
        switch score {
        case 2: return "Excellent! You maintained great facial expressions with frequent smiling."
        case 1: return "Good expressions, but try to smile more often to appear more engaging."
        default: return "You need to smile much more to appear engaging and confident."
        }
    }
    
    private var fillerWordsDescription: String {
        let score = fillerWordsScore()
        let fillerWordsList = result.fillerCounts.compactMap { (word, count) in
            count > 0 ? "\(word) (\(count)x)" : nil
        }.joined(separator: ", ")
        
        switch score {
        case 2: 
            return totalFillerWords == 0 ? "Perfect! No filler words detected." : "Excellent control with minimal filler words: \(fillerWordsList)."
        case 1: 
            return "Good control, but try to reduce filler words: \(fillerWordsList)."
        default: 
            return "Too many filler words detected: \(fillerWordsList). Practice pausing instead of using fillers."
        }
    }
    
    private var paceDescription: String {
        let score = paceScore()
        let wpm = Int(result.wpm)
        switch score {
        case 2: return "Perfect speaking pace at \(wpm) words per minute. Keep it up!"
        case 1: return "Acceptable pace at \(wpm) wpm, but try to aim for 110-150 wpm for optimal clarity."
        default: 
            if result.wpm < 90 {
                return "Speaking too slowly at \(wpm) wpm. Try to speak more confidently and increase your pace."
            } else {
                return "Speaking too fast at \(wpm) wpm. Slow down to improve clarity and comprehension."
            }
        }
    }
    
    private func eyeContactDescription() -> String {
        guard let eyeContactValue = result.eyeContactScore else { 
            return "Eye contact analysis will be available in future updates."
        }
        let score = eyeContactScore()
        switch score {
        case 2:
            return "Perfect! You maintained excellent eye contact at the ideal level."
        case 1:
            if eyeContactValue < 60 {
                return "Good, but try to maintain more consistent eye contact with your audience."
            } else {
                return "Good, but try to vary your gaze occasionally to appear more natural."
            }
        default:
            if eyeContactValue < 40 {
                return "Focus on maintaining more eye contact with your audience to build connection and trust."
            } else {
                return "You're looking too intensely. Try to blink and look away occasionally for a more natural delivery."
            }
        }
    }
    
    // MARK: - Color methods
    
    private func expressionColor() -> Color {
        let score = smileScore()
        switch score {
        case 2: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    private func paceColor() -> Color {
        let score = paceScore()
        switch score {
        case 2: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    private func fillerWordsColor() -> Color {
        let score = fillerWordsScore()
        switch score {
        case 2: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    private func eyeContactColor() -> Color {
        guard result.eyeContactScore != nil else { return .purple }
        let score = eyeContactScore()
        switch score {
        case 2: return .green
        case 1: return .orange
        default: return .red
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
                
                HStack{
                    Text(confidenceLevel)
                        .font(.footnote)
                        .frame(minHeight: 30)
                        .fontWeight(.regular)
                        .foregroundColor(confidenceColor)
                        .padding(.horizontal, 32)
                        .background(confidenceColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(confidenceColor, lineWidth: 2)
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
                                description: expressionDescription
                            )
                            
                            // Filler Words Indicator
                            IndicatorCard(
                                icon: "indicator2",
                                iconColor: fillerWordsColor(),
                                title: fillerWordsCategory,
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
                                value: result.eyeContactScore != nil ? String(format: "%.1f%%", result.eyeContactScore!) : "Coming Soon",
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
