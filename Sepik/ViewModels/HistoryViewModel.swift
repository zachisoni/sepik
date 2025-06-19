import Foundation
import SwiftUI
import SwiftData

@MainActor
internal class HistoryViewModel: ObservableObject {
    @Published var sessions: [SessionDisplayData] = []
    @Published var expandedSessionID: UUID?
    @Published var isEditing: Bool = false
    @Published var selectedSessionIDs: Set<UUID> = []
    
    private var dataManager: DataManager?
    private var modelContext: ModelContext?
    
    struct SessionDisplayData: Identifiable {
        let id: UUID
        let session: PracticeSession
        let result: AnalysisResult
        let assessment: String
        let color: Color
        let formattedDate: String
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
        loadSessions()
        
        // Seed mock data for development if no sessions exist
        let sessionCountBeforeSeeding = sessions.count
        dataManager?.seedMockDataIfNeeded()
        if sessionCountBeforeSeeding == 0 {
            loadSessions()
        }
    }
    
    func loadSessions() {
        guard let dataManager = dataManager else { 
            print("DEBUG: DataManager is nil in loadSessions")
            return 
        }
        let practiceSessions = dataManager.fetchPracticeSessions()
        sessions = practiceSessions.compactMap { session in
            guard let result = session.result else { return nil }
            return SessionDisplayData(
                id: session.id,
                session: session,
                result: result,
                assessment: getAssessment(for: result).0,
                color: getAssessment(for: result).1,
                formattedDate: formatDate(session.date)
            )
        }
        print("DEBUG: Loaded \(sessions.count) sessions in HistoryViewModel")
    }
    
    func addSession(_ result: AnalysisResult) {
        guard let dataManager = dataManager else { return }
        dataManager.savePracticeSession(result)
        loadSessions()
    }
    
    func addTestSession() {
        let testResult = AnalysisResult(
            duration: 120,
            smileFrames: 10,
            neutralFrames: 15,
            totalWords: 200,
            wpm: 125,
            fillerCounts: ["uh": 2, "like": 1],
            videoURL: nil,
            eyeContactScore: 65.5
        )
        addSession(testResult)
    }
    
    func deleteSession(_ session: PracticeSession) {
        guard let dataManager = dataManager else { return }
        dataManager.deletePracticeSession(session)
        loadSessions()
    }
    
    func deleteAllSessions() {
        guard let dataManager = dataManager else { return }
        dataManager.deleteAllPracticeSessions()
        loadSessions()
    }
    
    func clearAndRebuildData() {
        guard let dataManager = dataManager else { return }
        dataManager.clearAllData()
        dataManager.seedMockDataIfNeeded()
        loadSessions()
    }
    
    // New delete functionality from yeha-result
    func deleteSelectedSessions() {
        let sessionsToDelete = sessions.filter { selectedSessionIDs.contains($0.id) }
        for session in sessionsToDelete {
            deleteSession(session.session)
        }
        selectedSessionIDs.removeAll()
        isEditing = false
    }
    
    func toggleSelection(_ sessionID: UUID, selected: Bool) {
        if selected {
            selectedSessionIDs.insert(sessionID)
        } else {
            selectedSessionIDs.remove(sessionID)
        }
    }
    
    func toggleExpansion(_ sessionID: UUID, isExpanded: Bool) {
        expandedSessionID = isExpanded ? sessionID : nil
    }
    
    // Updated assessment logic with new scoring system
    private func getAssessment(for result: AnalysisResult) -> (String, Color) {
        // Calculate smile percentage
        let total = result.smileFrames + result.neutralFrames
        let smilePercentage = total > 0 ? Double(result.smileFrames) / Double(total) * 100 : 0
        
        // Calculate total filler words
        let totalFillerWords = result.fillerCounts.values.reduce(0, +)
        
        // Scoring functions based on new criteria
        func smileScore() -> Int {
            if smilePercentage > 30 { return 2 } else if smilePercentage >= 15 { return 1 } else { return 0 }
        }
        
        func fillerWordsScore() -> Int {
            if totalFillerWords <= 2 { return 2 } else if totalFillerWords <= 4 { return 1 } else { return 0 }
        }
        
        func paceScore() -> Int {
            let wpm = result.wpm
            if wpm >= 110 && wpm <= 150 { return 2 } else if (wpm >= 90 && wpm <= 109) || (wpm >= 151 && wpm <= 170) { return 1 } else { return 0 }
        }
        
        func eyeContactScore() -> Int {
            guard let eyeContact = result.eyeContactScore else { return 0 }
            if eyeContact >= 60 && eyeContact <= 70 { 
                return 2 
            } else if (eyeContact >= 40 && eyeContact <= 59) || (eyeContact >= 71 && eyeContact <= 80) { 
                return 1 
            } else { 
                return 0 
            }
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
