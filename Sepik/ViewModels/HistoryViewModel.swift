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
        sessions = dataManager.fetchPracticeSessions()
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
} 