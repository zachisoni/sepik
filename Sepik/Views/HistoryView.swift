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
                List {
                                            ForEach(viewModel.sessions, id: \.id) { session in
                            if let result = session.result {
                                NavigationLink(destination: ResultView(result: result, sessionDate: session.date, isFromAnalysis: false)) {
                                HistoryRowView(session: session)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    viewModel.deleteSession(session)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                    
                    // Add spacing at bottom for tab bar
                    Color.clear
                        .frame(height: 100)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let session = viewModel.sessions[index]
            viewModel.deleteSession(session)
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.vertical, 2)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
    }
}
