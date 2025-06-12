//
//  MainTabView.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PracticeView()
                .tabItem {
                    tabItemView(title: "Analysis", imageName: "analysis", tag: 0)
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    tabItemView(title: "History", imageName: "history", tag: 1)
                }
                .tag(1)
        }
        .background(Color.white)
        .tint(Color.orange)
//        .ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder
    func tabItemView(title: String, imageName: String, tag: Int) -> some View {
        VStack {
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .frame(width: 30, height: 30)
                .foregroundColor(selectedTab == tag ? .orange : .gray)
            Text(title)
                .font(.caption)
                .foregroundColor(selectedTab == tag ? .orange : .gray)
        }
    }
}

#Preview {
    MainTabView()
}

