import SwiftUI

struct ResultView: View {
    let result: AnalysisResult

    private var smilePct: Double {
        let total = result.smileFrames + result.neutralFrames
        return total > 0 ? Double(result.smileFrames) / Double(total) : 0
    }

    private var fillerPct: Double {
        guard result.totalWords > 0 else { return 0 }
        let totalFillers = result.fillerCounts.values.reduce(0, +)
        return Double(totalFillers) / Double(result.totalWords)
    }

    private var paceCategory: String {
        switch result.wpm {
        case ..<110: return "Slow"
        case 110...150: return "Targeted"
        default: return "Too Fast"
        }
    }

    private var pacePct: Double {
        // Normalize around target (110–150wpm)
        let minWPM = 100.0, maxWPM = 160.0
        let clamped = min(max(result.wpm, minWPM), maxWPM)
        return (clamped - minWPM) / (maxWPM - minWPM)
    }

    var body: some View {
        ZStack {
            Color("AccentColor")
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 16) {
                        VStack {
                            Image("indicator1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            Text(smilePct >= 0.5 ? "Smile" : "Neutral")
                                .font(.headline)
                        }
                        Spacer()
                        VStack {
                            Image("indicator2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            Text(paceCategory)
                                .font(.headline)
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rehearsal Time")
                            .font(.headline)
                        Text("\(Int(result.duration) / 60)min \(Int(result.duration) % 60)sec")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)

                    Group {
                        DisclosureGroup("Filler Words") {
                            ProgressView(value: fillerPct)
                                .accentColor(Color("AccentSecondary"))
                            Text("You used \(result.fillerCounts.values.reduce(0, +)) filler words out of \(result.totalWords). Try practicing with short pauses instead.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        DisclosureGroup("Smile") {
                            ProgressView(value: smilePct)
                                .accentColor(Color("AccentSecondary"))
                            Text("You smiled \(smilePct >= 0.5 ? "a lot" : "less frequently"). Keep it up!")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        DisclosureGroup("Pace") {
                            ProgressView(value: pacePct)
                                .accentColor(Color("AccentSecondary"))
                            Text(paceCategory == "Slow" ? "You speak too slowly, try to speed up." : paceCategory == "Too Fast" ? "You speak too fast, try slowing down." : "Your pace is on target. Great job!")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        NavigationLink(destination: HomeView()) {
                            Text("Back to Home")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(Color("AccentPrimary"))
                                .cornerRadius(8)
                        }
                        NavigationLink(destination: VideoInputView()) {
                            Text("Restart Practice")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentPrimary"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical)
            }
        }
        .navigationBarBackButtonHidden(true)
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
    }
} 