import Foundation

class InputNameViewModel: ObservableObject {
    @Published var userName: String = ""
    private let userManager = UserManager.shared
    
    var canProceed: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init() {
        // Don't pre-fill, start with empty field
        userName = ""
    }
    
    func saveUserName() {
        userManager.setUserName(userName)
    }
} 