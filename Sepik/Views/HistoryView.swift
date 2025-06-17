import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.modelContext) private var modelContext
    
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
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.sessions) { sessionData in
                    SessionRowView(
                        sessionData: sessionData,
                        isExpanded: viewModel.expandedSessionID == sessionData.id,
                        isEditing: viewModel.isEditing,
                        isSelected: viewModel.selectedSessionIDs.contains(sessionData.id),
                        onSelect: { viewModel.toggleSelection(sessionData.id, selected: $0) },
                        onTap: { viewModel.toggleExpansion(sessionData.id, isExpanded: $0) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    print("Trash/Delete button tapped, isEditing: \(viewModel.isEditing)")
                    if viewModel.isEditing {
                        viewModel.deleteSelectedSessions()
                    } else {
                        viewModel.isEditing = true
                    }
                }) {
                    if viewModel.isEditing {
                        Text("Delete")
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Image(systemName: "trash")
                            .foregroundStyle(.white)
                            .font(.system(size: 16))
                    }
                }
                .disabled(viewModel.isEditing && viewModel.selectedSessionIDs.isEmpty)
            }
            if viewModel.isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        print("Cancel button tapped")
                        viewModel.isEditing = false
                        viewModel.selectedSessionIDs.removeAll()
                    }) {
                        Text("Cancel")
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
    }
}

struct SessionRowView: View {
    let sessionData: HistoryViewModel.SessionDisplayData
    let isExpanded: Bool
    let isEditing: Bool
    let isSelected: Bool
    let onSelect: (Bool) -> Void
    let onTap: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SessionHeaderView(
                assessment: sessionData.assessment,
                color: sessionData.color,
                formattedDate: sessionData.formattedDate,
                isEditing: isEditing,
                isSelected: isSelected,
                isExpanded: isExpanded,
                onTap: { onTap(!isExpanded) },
                onSelect: { onSelect(!isSelected) }
            )
            
            if isExpanded {
                SessionDetailsView(
                    result: sessionData.result,
                    sessionDate: sessionData.session.date
                )
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 2)
        }
    }
}

struct SessionHeaderView: View {
    let assessment: String
    let color: Color
    let formattedDate: String
    let isEditing: Bool
    let isSelected: Bool
    let isExpanded: Bool
    let onTap: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: isEditing ? onSelect : onTap) {
            HStack(spacing: 12) {
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .red : .gray)
                        .font(.system(size: 20))
                }
                
                AssessmentBadgeView(assessment: assessment, color: color)
                
                Spacer()
                
                Text(formattedDate)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
                
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
    }
}

struct AssessmentBadgeView: View {
    let assessment: String
    let color: Color
    
    var body: some View {
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
    }
}

struct SessionDetailsView: View {
    let result: AnalysisResult
    let sessionDate: Date
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    MetricRowView(
                        imageName: "indicator1",
                        label: "Smile: \(result.smileFrames)x",
                        imageSize: CGSize(width: 24, height: 24)
                    )
                    
                    MetricRowView(
                        imageName: "indicator2",
                        label: "Filler Words: \(result.fillerCounts.values.reduce(0, +))",
                        imageSize: CGSize(width: 24, height: 24)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    MetricRowView(
                        imageName: "indicator3",
                        label: "Speaking Pace:",
                        imageSize: CGSize(width: 24, height: 24)
                    )
                    
                    MetricRowView(
                        imageName: "indicator4",
                        label: "Eye Contact: \(Int(result.eyeContactPercentage))%",
                        imageSize: CGSize(width: 20, height: 20)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Spacer()
                NavigationLink(destination: ResultView(result: result, sessionDate: sessionDate)) {
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

struct MetricRowView: View {
    let imageName: String
    let label: String
    let imageSize: CGSize
    
    var body: some View {
        HStack(spacing: 4) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize.width, height: imageSize.height)
            Text(label)
                .foregroundColor(.black)
                .font(.subheadline)
        }
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
