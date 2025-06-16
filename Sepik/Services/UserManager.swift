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
    
    static let shared = UserManager()
    
    private init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? ""
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
} 