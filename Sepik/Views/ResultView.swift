import SwiftUI

struct ResultView: View {
    let result: AnalysisResult
    let sessionDate: Date?
    let isFromAnalysis: Bool
    private let userManager = UserManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(result: AnalysisResult, sessionDate: Date? = nil, isFromAnalysis: Bool = false) {
        self.result = result
        self.sessionDate = sessionDate
        self.isFromAnalysis = isFromAnalysis
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
                    HStack {
                        if isFromAnalysis {
                            NavigationLink(destination: TabContainerView()) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Back")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(.white)
                            }
                        } else {
                            Button(action: {
                                dismiss()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Back")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("See what you might")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("improve here, \(userManager.getUserName())!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let session = getSessionDate() {
                            Text("Result on \(session)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Rehearsal Time Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rehearsal Time: \(formatDuration(result.duration))")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Indicator Cards
                        VStack(spacing: 12) {
                            // Filler Words Indicator
                            IndicatorCard(
                                icon: "mouth.fill",
                                iconColor: .orange,
                                title: "Filler Words",
                                value: "\(totalFillerWords) words",
                                description: fillerWordsDescription
                            )
                            
                            // Expression Indicator
                            IndicatorCard(
                                icon: expressionIcon(),
                                iconColor: expressionColor(),
                                title: expressionQuality,
                                value: String(format: "%.1f%%", smilePercentage),
                                description: expressionDescription()
                            )
                            
                            // Pace Indicator
                            IndicatorCard(
                                icon: paceIcon(),
                                iconColor: paceColor(),
                                title: paceCategory,
                                value: "\(Int(result.wpm)) wpm",
                                description: paceDescription
                            )
                        }
                        .padding(.horizontal)
                        
                        // Restart Analysis Button
                        NavigationLink(destination: TabContainerView()) {
                            Text("Restart Analysis")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentPrimary"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 100) // Space for tab bar if needed
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)min \(seconds) s"
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
            // Icon
            ZStack {
                Circle()
                    .stroke(iconColor, lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            .frame(minWidth: 50)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(value)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Text(description)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .minimumScaleFactor(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
        }
        .frame(height: 120)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
            ResultView(result: AnalysisResult(
                duration: 1850,
                smileFrames: 12,
                neutralFrames: 8,
                totalWords: 340,
                wpm: 110,
                fillerCounts: ["uh": 5, "like": 3, "you know": 2]
            ))
        }
        .modelContainer(for: PracticeSession.self)
    }
} 
