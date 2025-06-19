//
//  MainTabView.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            Spacer()
            
            // Analysis Tab
            Button(action: {
                selectedTab = 0
            }, label: {
                VStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(selectedTab == 0 ? Color("AccentSecondary") : .gray)
                    Text("Analysis")
                        .font(.caption)
                        .foregroundColor(selectedTab == 0 ? Color("AccentSecondary") : .gray)
                }
            })
            
            Spacer()
            
            // History Tab
            Button(action: {
                selectedTab = 1
            }, label: {
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(selectedTab == 1 ? Color("AccentSecondary") : .gray)
                    Text("History")
                        .font(.caption)
                        .foregroundColor(selectedTab == 1 ? Color("AccentSecondary") : .gray)
                }
            })
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
}

#Preview {
    MainTabView(selectedTab: .constant(0))
}
