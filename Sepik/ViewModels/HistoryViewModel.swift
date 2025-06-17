import Foundation
import SwiftUI
import SwiftData

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var sessions: [SessionDisplayData] = []
    @Published var expandedSessionID: UUID? = nil
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
        dataManager?.seedMockDataIfNeeded()
        loadSessions()
    }
    
    func loadSessions() {
        guard let dataManager = dataManager else { return }
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
    }
    
    func addSession(_ result: AnalysisResult) {
        guard let dataManager = dataManager else { return }
        dataManager.savePracticeSession(result)
        loadSessions()
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
    
    private func getAssessment(for result: AnalysisResult) -> (String, Color) {
        let total = result.smileFrames + result.neutralFrames
        let smilePct = total > 0 ? Double(result.smileFrames) / Double(total) : 0
        return smilePct >= 0.3 ? ("Confident", Color(red: 0.6, green: 0.8, blue: 0.6)) : ("Needs Improvement", .orange)
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy • h:mm"
        return dateFormatter.string(from: date)
    }
}
