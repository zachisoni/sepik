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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PracticeSession.self,
            AnalysisResult.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Could not create ModelContainer: \(error)")
            // Fallback: try to create a new container by deleting old data
            do {
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(Color("AccentPrimary"))
                .tint(Color("AccentPrimary"))
        }
        .modelContainer(sharedModelContainer)
    }
}

struct ContentView: View {
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        if userManager.hasCompletedOnboarding {
            TabContainerView(initialTab: 0)
        } else {
            NavigationStack {
                OnboardingView()
            }
        }
    }
}
