import Foundation
import SwiftData

@Model
class AnalysisResult {
    var duration: TimeInterval
    var smileFrames: Int
    var neutralFrames: Int
    var totalWords: Int
    var wpm: Double
    var fillerCountsData: Data // Store dictionary as Data
    
    // Computed property to access filler counts as dictionary
    var fillerCounts: [String: Int] {
        get {
            guard let decoded = try? JSONDecoder().decode([String: Int].self, from: fillerCountsData) else {
                return [:]
            }
            return decoded
        }
        set {
            fillerCountsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    init(duration: TimeInterval, smileFrames: Int, neutralFrames: Int, totalWords: Int, wpm: Double, fillerCounts: [String: Int]) {
        self.duration = duration
        self.smileFrames = smileFrames
        self.neutralFrames = neutralFrames
        self.totalWords = totalWords
        self.wpm = wpm
        self.fillerCountsData = (try? JSONEncoder().encode(fillerCounts)) ?? Data()
    }
} 
