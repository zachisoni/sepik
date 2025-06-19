//
//  DataManager.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import Foundation
import SwiftData

@MainActor
internal class DataManager: ObservableObject {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Practice Session Operations
    
    func savePracticeSession(_ result: AnalysisResult) {
        let session = PracticeSession(date: Date(), result: result)
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            let eyeContactScoreText = result.eyeContactScore?.description ?? "nil"
            print("DEBUG: Successfully saved practice session with eye contact score: \(eyeContactScoreText)")
            // Post notification that new session was saved
            NotificationCenter.default.post(name: NSNotification.Name("NewSessionSaved"), object: nil)
        } catch {
            print("Failed to save practice session: \(error)")
        }
    }
    
    func fetchPracticeSessions() -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            print("DEBUG: Successfully fetched \(sessions.count) practice sessions")
            return sessions
        } catch {
            print("ERROR: Failed to fetch practice sessions: \(error)")
            print("ERROR Details: \(error.localizedDescription)")
            return []
        }
    }
    
    func deletePracticeSession(_ session: PracticeSession) {
        modelContext.delete(session)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete practice session: \(error)")
        }
    }
    
    func deleteAllPracticeSessions() {
        let sessions = fetchPracticeSessions()
        for session in sessions {
            modelContext.delete(session)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete all practice sessions: \(error)")
        }
    }
    
    // MARK: - Development Helper
    
    func seedMockDataIfNeeded() {
        let existingSessions = fetchPracticeSessions()
        guard existingSessions.isEmpty else { return }
        
        // Create mock data for development
        let mockResults = [
            AnalysisResult(duration: 125, smileFrames: 8, neutralFrames: 12, totalWords: 180, wpm: 120, fillerCounts: ["uh": 3, "like": 2], eyeContactScore: 65.5),
            AnalysisResult(duration: 98, smileFrames: 15, neutralFrames: 5, totalWords: 145, wpm: 135, fillerCounts: ["uh": 1, "like": 4], eyeContactScore: 55.3),
            AnalysisResult(duration: 156, smileFrames: 10, neutralFrames: 18, totalWords: 220, wpm: 105, fillerCounts: ["uh": 6, "like": 3, "you know": 2], eyeContactScore: 45.8),
            AnalysisResult(duration: 89, smileFrames: 12, neutralFrames: 8, totalWords: 130, wpm: 140, fillerCounts: ["uh": 2, "like": 1], eyeContactScore: 68.2),
            AnalysisResult(duration: 134, smileFrames: 9, neutralFrames: 15, totalWords: 195, wpm: 115, fillerCounts: ["uh": 4, "like": 5], eyeContactScore: 75.7),
            AnalysisResult(duration: 167, smileFrames: 18, neutralFrames: 12, totalWords: 245, wpm: 125, fillerCounts: ["uh": 3, "like": 2, "you know": 1], eyeContactScore: 63.9)
        ]
        
        let calendar = Calendar.current
        let now = Date()
        
        for (index, result) in mockResults.enumerated() {
            let daysAgo = index
            let sessionDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let timeOffset = calendar.date(byAdding: .minute, value: index * 20, to: sessionDate) ?? sessionDate
            
            let session = PracticeSession(date: timeOffset, result: result)
            modelContext.insert(session)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to seed mock data: \(error)")
        }
    }
    
    func clearAllData() {
        // Delete all existing data
        let sessions = fetchPracticeSessions()
        for session in sessions {
            modelContext.delete(session)
        }
        
        // Also try to delete any orphaned AnalysisResult objects
        do {
            let analysisResults = try modelContext.fetch(FetchDescriptor<AnalysisResult>())
            for result in analysisResults {
                modelContext.delete(result)
            }
        } catch {
            print("Failed to fetch AnalysisResult objects: \(error)")
        }
        
        do {
            try modelContext.save()
            print("DEBUG: Successfully cleared all data")
        } catch {
            print("Failed to clear all data: \(error)")
        }
    }
} 
