import Foundation
import SwiftData

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var sessions: [PracticeSession] = []
    
    private var dataManager: DataManager?
    private var modelContext: ModelContext?
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataManager = DataManager(modelContext: modelContext)
        loadSessions()
        
        // Seed mock data for development if no sessions exist
        dataManager?.seedMockDataIfNeeded()
        loadSessions()
    }
    
    func loadSessions() {
        guard let dataManager = dataManager else { return }
        sessions = dataManager.fetchPracticeSessions()
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
} 