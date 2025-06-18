//
//  UserManager.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import Foundation

class UserManager: ObservableObject {
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    static let shared = UserManager()
    
    private init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func setUserName(_ name: String) {
        userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func getUserName() -> String {
        return userName.isEmpty ? "User" : userName
    }
    
    func hasUserName() -> Bool {
        return !userName.isEmpty
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userName = ""
    }
} 