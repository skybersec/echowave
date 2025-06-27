import SwiftUI

struct SurveysListView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var surveys: [Survey] = []
    @State private var selectedFilter = SurveyFilter.all
    @State private var searchText = ""
    @State private var showingSurveyDetail = false
    @State private var selectedSurvey: Survey?
    
    enum SurveyFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        
        var icon: String {
            switch self {
            case .all: return "tray.2"
            case .active: return "clock"
            case .completed: return "checkmark.circle"
            }
        }
    }
    
    var filteredSurveys: [Survey] {
        let filtered = surveys.filter { survey in
            switch selectedFilter {
            case .all:
                return true
            case .active:
                return survey.isActive && !survey.canViewResults
            case .completed:
                return survey.canViewResults
            }
        }
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SurveyFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                if surveys.isEmpty {
                    emptyStateView
                } else if filteredSurveys.isEmpty {
                    noResultsView
                } else {
                    surveysList
                }
            }
            .navigationTitle("My Surveys")
            .searchable(text: $searchText, prompt: "Search surveys")
            .onAppear {
                loadMockSurveys()
            }
            .sheet(item: $selectedSurvey) { survey in
                SurveyDetailView(survey: survey)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No surveys yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first survey to start collecting feedback")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: CreateSurveyView()) {
                Text("Create Survey")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No surveys found")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Try adjusting your filters or search")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private var surveysList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredSurveys) { survey in
                    SurveyCard(survey: survey) {
                        selectedSurvey = survey
                    }
                }
            }
            .padding()
        }
    }
    
    private func loadMockSurveys() {
        // Mock data for demonstration
        surveys = [
            Survey(
                id: "1",
                userId: authManager.currentUser?.id ?? "",
                templateType: .individual,
                minResponses: 10,
                urlToken: "abc123",
                createdAt: Date().addingTimeInterval(-86400 * 7),
                title: "Q4 Performance Review",
                description: "Gathering feedback for year-end review",
                questions: [],
                responseCount: 12,
                isActive: true
            ),
            Survey(
                id: "2",
                userId: authManager.currentUser?.id ?? "",
                templateType: .team,
                minResponses: 10,
                urlToken: "def456",
                createdAt: Date().addingTimeInterval(-86400 * 3),
                title: "Team Health Check",
                description: "Monthly team dynamics survey",
                questions: [],
                responseCount: 7,
                isActive: true
            ),
            Survey(
                id: "3",
                userId: authManager.currentUser?.id ?? "",
                templateType: .product,
                minResponses: 15,
                urlToken: "ghi789",
                createdAt: Date().addingTimeInterval(-86400 * 14),
                title: "App Usability Feedback",
                description: nil,
                questions: [],
                responseCount: 18,
                isActive: false
            )
        ]
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.teal : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct SurveyCard: View {
    let survey: Survey
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(survey.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let description = survey.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: survey.templateType.icon)
                        .font(.title2)
                        .foregroundColor(.teal)
                }
                
                Divider()
                
                HStack {
                    // Response count
                    Label("\(survey.responseCount)/\(survey.minResponses)", systemImage: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(survey.canViewResults ? .green : .orange)
                    
                    Spacer()
                    
                    // Status
                    if survey.canViewResults {
                        Label("View Results", systemImage: "chart.bar.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.teal)
                    } else if survey.isActive {
                        Label("Collecting", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Label("Closed", systemImage: "xmark.circle")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Date
                    Text(survey.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SurveyDetailView: View {
    let survey: Survey
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Survey header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: survey.templateType.icon)
                                .font(.title)
                                .foregroundColor(.teal)
                            
                            Text(survey.templateType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if survey.canViewResults {
                                NavigationLink(destination: Text("Results View - Coming Soon")) {
                                    Label("View Results", systemImage: "chart.bar")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.teal)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        Text(survey.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let description = survey.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 20) {
                        StatBox(
                            title: "Responses",
                            value: "\(survey.responseCount)",
                            subtitle: "of \(survey.minResponses) needed",
                            color: survey.canViewResults ? .green : .orange
                        )
                        
                        StatBox(
                            title: "Status",
                            value: survey.isActive ? "Active" : "Closed",
                            subtitle: survey.canViewResults ? "Results available" : "Collecting feedback",
                            color: survey.isActive ? .blue : .gray
                        )
                    }
                    
                    // Share section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share Survey")
                            .font(.headline)
                        
                        HStack {
                            Text(survey.shareURL.absoluteString)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.secondary)
                            
                            Button {
                                UIPasteboard.general.string = survey.shareURL.absoluteString
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.teal)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Questions preview
                    if !survey.questions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Questions (\(survey.questions.count))")
                                .font(.headline)
                            
                            ForEach(survey.questions.prefix(3)) { question in
                                HStack {
                                    Image(systemName: question.type.icon)
                                        .foregroundColor(.teal)
                                        .frame(width: 20)
                                    
                                    Text(question.prompt)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            
                            if survey.questions.count > 3 {
                                Text("+ \(survey.questions.count - 3) more questions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Survey Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SurveysListView_Previews: PreviewProvider {
    static var previews: some View {
        SurveysListView()
            .environmentObject(AuthManager())
    }
} 