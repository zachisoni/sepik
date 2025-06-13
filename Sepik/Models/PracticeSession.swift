import Foundation
import SwiftData

@Model
class PracticeSession {
    var id: UUID
    var date: Date
    var result: AnalysisResult?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy • h:mm"
        return formatter.string(from: date)
    }
    
    init(date: Date, result: AnalysisResult) {
        self.id = UUID()
        self.date = date
        self.result = result
    }
} 