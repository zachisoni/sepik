import Foundation

struct AnalysisResult {
    let duration: TimeInterval
    let smileFrames: Int
    let neutralFrames: Int
    let totalWords: Int
    let wpm: Double
    let fillerCounts: [String: Int]
} 
