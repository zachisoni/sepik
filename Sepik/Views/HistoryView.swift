import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var expandedSessionID: UUID? = nil
    private let userManager = UserManager.shared
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor(named: "AccentPrimary")
        appearance.shadowColor = nil
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            Color("AccentPrimary")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("\(userManager.getUserName())'s Speaking\nAnalysis History")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                
                // History List
                if viewModel.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Text("No analysis history yet")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Upload a video and start your first analysis!")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Button("Refresh") {
                            viewModel.loadSessions()
                        }
                        .foregroundColor(Color("AccentPrimary"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                        
                        Button("Reset Data (Debug)") {
                            viewModel.clearAndRebuildData()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.6))
                        .cornerRadius(8)
                        
                        Button("Add Test Session") {
                            viewModel.addTestSession()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.6))
                        .cornerRadius(8)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.sessions, id: \.id) { session in
                                if let result = session.result {
                                    let (assessment, color) = getAssessment(for: result)
                                    let formattedDate = formatDate(session.date)
                                    
                                    CombinedHistoryView(
                                        session: session,
                                        result: result,
                                        assessment: assessment,
                                        color: color,
                                        formattedDate: formattedDate,
                                        isExpanded: expandedSessionID == session.id,
                                        onTap: { isExpanded in
                                            withAnimation {
                                                expandedSessionID = isExpanded ? session.id : nil
                                            }
                                        },
                                        onDelete: {
                                            viewModel.deleteSession(session)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 100) // Space for tab bar
                    }
                }
                
                Spacer()
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.1))
        .onAppear {
            viewModel.configure(with: modelContext)
            viewModel.loadSessions() // Always reload when view appears
        }
        .refreshable {
            viewModel.loadSessions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewSessionSaved"))) { _ in
            viewModel.loadSessions()
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let session = viewModel.sessions[index]
            viewModel.deleteSession(session)
        }
    }
    
    private func getAssessment(for result: AnalysisResult) -> (String, Color) {
        // Calculate smile percentage
        let total = result.smileFrames + result.neutralFrames
        let smilePercentage = total > 0 ? Double(result.smileFrames) / Double(total) * 100 : 0
        
        // Calculate total filler words
        let totalFillerWords = result.fillerCounts.values.reduce(0, +)
        
        // Scoring functions based on new criteria
        func smileScore() -> Int {
            if smilePercentage > 30 { return 2 }
            else if smilePercentage >= 15 { return 1 }
            else { return 0 }
        }
        
        func fillerWordsScore() -> Int {
            if totalFillerWords <= 2 { return 2 }
            else if totalFillerWords <= 4 { return 1 }
            else { return 0 }
        }
        
        func paceScore() -> Int {
            let wpm = result.wpm
            if wpm >= 110 && wpm <= 150 { return 2 }
            else if (wpm >= 90 && wpm <= 109) || (wpm >= 151 && wpm <= 170) { return 1 }
            else { return 0 }
        }
        
        func eyeContactScore() -> Int {
            guard let eyeContact = result.eyeContactScore else { return 0 }
            if eyeContact >= 60 && eyeContact <= 70 { return 2 }
            else if (eyeContact >= 40 && eyeContact <= 59) || (eyeContact >= 71 && eyeContact <= 80) { return 1 }
            else { return 0 }
        }
        
        // Calculate total confidence score
        let totalScore = smileScore() + fillerWordsScore() + paceScore() + eyeContactScore()
        
        // Determine confidence level and color
        if totalScore >= 7 {
            return ("Confident", .green)
        } else if totalScore >= 5 {
            return ("Neutral", .orange)
        } else {
            return ("Nervous", .red)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy • h:mm"
        return dateFormatter.string(from: date)
    }
}

struct CombinedHistoryView: View {
    let session: PracticeSession
    let result: AnalysisResult
    let assessment: String
    let color: Color
    let formattedDate: String
    let isExpanded: Bool
    let onTap: (Bool) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                onTap(!isExpanded)
            }) {
                HStack(spacing: 12) {
                    Text(assessment)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundColor(color)
                        .padding(.horizontal, 16)
                        .frame(height: 30)
                        .background(color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(color, lineWidth: 2)
                        )
                        .cornerRadius(5)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack(alignment: .top, spacing: 16) {
                        // Left column
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image("indicator1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text("Smile: \(result.smileFrames)x")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline)
                            }
                            
                            HStack(spacing: 4) {
                                Image("indicator2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Filler Words: \(result.fillerCounts.values.reduce(0, +))")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Right column
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image("indicator3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text("Pace: \(Int(result.wpm)) wpm")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline)
                            }
                            
                            HStack(spacing: 4) {
                                Image("indicator4")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Eye Contact: \(result.eyeContactScore != nil ? String(format: "%.0f%%", result.eyeContactScore!) : "N/A")")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Spacer()
                        NavigationLink(destination: ResultView(result: result, sessionDate: session.date, isFromAnalysis: false)) {
                            Text("See details")
                                .font(.footnote)
                                .foregroundColor(.accentPrimary)
                        }
                    }
                    .padding(.bottom)
                }
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HistoryView()
        }
        .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
    }
}

extension AnalysisResult {
    var eyeContactPercentage: Double {
        return 80.0 // Default value for preview
    }
}
