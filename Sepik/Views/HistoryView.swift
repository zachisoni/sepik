//
//  HistoryView.swift
//  Sepik
//
//  Created by Yonathan Handoyo on 12/06/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 1
    private let userManager = UserManager.shared
    
    var body: some View {
        ZStack {
            Color("AccentPrimary")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            // Back action - in a real app this would navigate back
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Back")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Text("\(userManager.getUserName())'s Speaking\nAnalysis History")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                
                // History List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sessions, id: \.id) { session in
                            if let result = session.result {
                                NavigationLink(destination: ResultView(result: result, sessionDate: session.date)) {
                                    HistoryRowView(session: session)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for tab bar
                }
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
        }
    }
}

struct HistoryRowView: View {
    let session: PracticeSession
    
    var body: some View {
        HStack {
            Text(session.formattedDate)
                .font(.system(size: 16))
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
    }
}
