import Foundation

class HomeViewModel: ObservableObject {
    @Published var userName: String = ""
    var canProceed: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
} 