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
            // Swipeable TabView for content
            TabView(selection: $selectedTab) {
                // Practice View (Tab 0)
                NavigationStack {
                    PracticeView()
                        .environment(\.modelContext, modelContext)
                }
                .tag(0)
                
                // History View (Tab 1)
                NavigationStack {
                    HistoryView()
                        .environment(\.modelContext, modelContext)
                }
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
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
