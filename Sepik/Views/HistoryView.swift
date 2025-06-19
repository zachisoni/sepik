import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext
    private let userManager = UserManager.shared
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.backgroundColor = UIColor(named: "AccentPrimary")
        appearance.shadowColor = nil
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.1))
        .tint(.white)
        .onAppear {
            viewModel.configure(with: modelContext)
            print("HistoryView appeared, isEditing: \(viewModel.isEditing)")
        }
        .toolbar { toolbarContent }
        .navigationBarBackButtonHidden(viewModel.isEditing)
        .refreshable {
            viewModel.loadSessions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewSessionSaved"))) { _ in
            viewModel.loadSessions()
        }
    }
    
    private var backgroundView: some View {
        VStack(spacing: 0) {
            Color("AccentPrimary")
                .frame(height: UIScreen.main.bounds.height * 0.4)
            Color.white
        }
        .ignoresSafeArea()
    }
    
    private var contentView: some View {
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
            if viewModel.sessions.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Text("No analysis history yet")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Upload a video and start your first analysis!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button("Refresh") {
                        viewModel.loadSessions()
                    }
                    .foregroundColor(Color("AccentPrimary"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    Button("Reset Data (Debug)") {
                        viewModel.clearAndRebuildData()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.6))
                    .cornerRadius(8)
                    
                    Button("Add Test Session") {
                        viewModel.addTestSession()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sessions, id: \.id) { sessionData in
                            CombinedHistoryView(
                                sessionData: sessionData,
                                isExpanded: viewModel.expandedSessionID == sessionData.id,
                                isEditing: viewModel.isEditing,
                                isSelected: viewModel.selectedSessionIDs.contains(sessionData.id),
                                onTap: { isExpanded in
                                    withAnimation {
                                        viewModel.toggleExpansion(sessionData.id, isExpanded: isExpanded)
                                    }
                                },
                                onSelect: { selected in
                                    viewModel.toggleSelection(sessionData.id, selected: selected)
                                },
                                onDelete: {
                                    viewModel.deleteSession(sessionData.session)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
            
            Spacer()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.isEditing {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    viewModel.isEditing = false
                    viewModel.selectedSessionIDs.removeAll()
                }
                .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Delete") {
                    viewModel.deleteSelectedSessions()
                }
                .foregroundColor(.red)
                .disabled(viewModel.selectedSessionIDs.isEmpty)
            }
        } else {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.isEditing = true
                }, label: {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                })
            }
        }
    }
}

struct CombinedHistoryView: View {
    let sessionData: HistoryViewModel.SessionDisplayData
    let isExpanded: Bool
    let isEditing: Bool
    let isSelected: Bool
    let onTap: (Bool) -> Void
    let onSelect: (Bool) -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                if !isEditing {
                    onTap(!isExpanded)
                }
            }, label: {
                HStack(spacing: 12) {
                    if isEditing {
                        Button(action: {
                            onSelect(!isSelected)
                        }, label: {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? .red : .gray)
                                .font(.title2)
                        })
                    }
                    
                    Text(sessionData.assessment)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundColor(sessionData.color)
                        .padding(.horizontal, 16)
                        .frame(height: 30)
                        .background(sessionData.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(sessionData.color, lineWidth: 2)
                        )
                        .cornerRadius(5)
                    
                    Spacer()
                    
                    Text(sessionData.formattedDate)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    if !isEditing {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
            })
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                if !isEditing {
                    Button(action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            if isExpanded && !isEditing {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack(alignment: .top, spacing: 16) {
                        // Left column
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image("indicator1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text("Smile: \(sessionData.result.smileFrames)x")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline)
                            }
                            
                            HStack(spacing: 4) {
                                Image("indicator2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Filler Words: \(sessionData.result.fillerCounts.values.reduce(0, +))")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Right column
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image("indicator3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text("Pace: \(Int(sessionData.result.wpm)) wpm")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline)
                            }
                            
                            HStack(spacing: 4) {
                                Image("indicator4")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Eye Contact: \(sessionData.result.eyeContactScore != nil ? String(format: "%.0f%%", sessionData.result.eyeContactScore ?? 0) : "N/A")")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Spacer()
                        NavigationLink(destination: ResultView(result: sessionData.result, sessionDate: sessionData.session.date, isFromAnalysis: false)) {
                            Text("See details")
                                .font(.footnote)
                                .foregroundColor(Color("AccentPrimary"))
                        }
                    }
                    .padding(.bottom)
                }
                .padding(.horizontal)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HistoryView()
        }
        .modelContainer(for: [PracticeSession.self, AnalysisResult.self])
    }
}

extension AnalysisResult {
    var eyeContactPercentage: Double {
        return 80.0 // Default value for preview
    }
}
