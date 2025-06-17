import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var expandedSessionID: UUID? = nil
    
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
            VStack(spacing: 0) {
                Color("AccentPrimary")
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                Color.white
            }
            .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.sessions, id: \.id) { session in
                        if let result = session.result {
                            let (assessment, color) = getAssessment(for: result)
                            let formattedDate = formatDate(session.date)
                            
                            CombinedHistoryView(
                                session: session,
                                result: result,
                                assessment: assessment,
                                color: color,
                                formattedDate: formattedDate,
                                isExpanded: expandedSessionID == session.id
                            ) { isExpanded in
                                withAnimation {
                                    expandedSessionID = isExpanded ? session.id : nil
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteSession( session)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 100) // Space for tab bar
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.1))
        .onAppear {
            viewModel.configure(with: modelContext)
        }
    }
    
    private func getAssessment(for result: AnalysisResult) -> (String, Color) {
        let total = result.smileFrames + result.neutralFrames
        let smilePct = total > 0 ? Double(result.smileFrames) / Double(total) : 0
        return smilePct >= 0.3 ? ("Confident", Color(red: 0.6, green: 0.8, blue: 0.6)) : ("Needs Improvement", .orange)
    }
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy • h:mm"
        return dateFormatter.string(from: date)
    }
}

struct CombinedHistoryView: View {
    let session: PracticeSession
    let result: AnalysisResult
    let assessment: String
    let color: Color
    let formattedDate: String
    let isExpanded: Bool
    let onTap: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                onTap(!isExpanded)
            }) {
                HStack(spacing: 12) {
                    Text(assessment)
                        .font(.footnote)
                        .fontWeight(.regular)
                        .foregroundColor(color)
                        .padding(.horizontal, 16)
                        .frame(height: 30)
                        .background(color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(color, lineWidth: 2)
                        )
                        .cornerRadius(5)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack(alignment: .top, spacing: 16) {
                        // Kolom kiri
                        VStack(alignment: .leading, spacing:  8) {
                            
                            HStack(spacing: 4) {
                                Image("indicator1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text("Smile: \(result.smileFrames)x")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline) // Atau ukuran font yang diinginkan
                            }
                            
                            HStack(spacing: 4) {
                                Image("indicator2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Filler Words: \(result.fillerCounts.values.reduce(0, +))")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline) // Atau ukuran font yang diinginkan
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Kolom kanan
                        VStack(alignment: .leading, spacing:  8) {
                            HStack(spacing: 4) {
                                Image("indicator3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text("Speaking Pace:")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline) // Atau ukuran font yang diinginkan
                            }
                            
                            HStack(spacing: 4) {
                                Image("indicator4")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Eye Contact: \(Int(result.eyeContactPercentage))%")
                                    .foregroundColor(Color.black)
                                    .font(.subheadline) // Atau ukuran font yang diinginkan
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading) // Memastikan seluruh HStack sejajar ke kiri
                    
                    HStack {
                        Spacer()
                        NavigationLink(destination: ResultView(result: result, sessionDate: session.date)) {
                            Text("See details")
                                .font(.callout)
                                .fontWeight(.semibold)
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
