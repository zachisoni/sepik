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
    @State private var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    
    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        ZStack {
            // Content based on selected tab
            Group {
                if selectedTab == 0 {
                    NavigationStack {
                        PracticeView()
                            .environment(\.modelContext, modelContext)
                    }
                } else {
                    NavigationStack {
                        HistoryView()
                            .environment(\.modelContext, modelContext)
                    }
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
        TabContainerView(initialTab: 0)
    }
    .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
} 
