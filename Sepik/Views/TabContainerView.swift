//
//  TabContainerView.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import AVKit

struct TabContainerView: View {
    @State private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            // Content based on selected tab
            Group {
                if selectedTab == 0 {
                    PracticeView()
                        .environment(\.modelContext, modelContext)
                } else {
                    HistoryView()
                        .environment(\.modelContext, modelContext)
                }
            }
            
            // Tab bar overlay
            VStack {
                Spacer()
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        TabContainerView()
    }
    .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
} 
