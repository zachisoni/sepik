import Foundation
import SwiftData

@Model
final class AnalysisResult {
    var duration: TimeInterval
    var smileFrames: Int
    var neutralFrames: Int
    var totalWords: Int
    var wpm: Double
    var fillerCountsData: Data // Store dictionary as Data
    var videoURLString: String? // Store video URL as string
    var eyeContactScore: Double? // Percentage of eye contact
    
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
    
    // Computed property to access video URL
    var videoURL: URL? {
        get {
            guard let urlString = videoURLString else { return nil }
            return URL(string: urlString)
        }
        set {
            videoURLString = newValue?.absoluteString
        }
    }
    
    init(duration: TimeInterval, smileFrames: Int, neutralFrames: Int, totalWords: Int, wpm: Double,
         fillerCounts: [String: Int], videoURL: URL? = nil, eyeContactScore: Double? = nil) {
        self.duration = duration
        self.smileFrames = smileFrames
        self.neutralFrames = neutralFrames
        self.totalWords = totalWords
        self.wpm = wpm
        self.fillerCountsData = (try? JSONEncoder().encode(fillerCounts)) ?? Data()
        self.videoURLString = videoURL?.absoluteString
        self.eyeContactScore = eyeContactScore
    }
} 
