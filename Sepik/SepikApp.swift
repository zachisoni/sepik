//
//  SepikApp.swift
//  Sepik
//
//  Created by reynaldo on 12/06/25.
//

import SwiftUI
import SwiftData

@main
struct SepikApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                OnboardingView()
            }
            .accentColor(Color("AccentPrimary"))
            .tint(Color("AccentPrimary"))
        }
        .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
    }
}
