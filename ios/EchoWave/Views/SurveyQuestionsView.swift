import SwiftUI

struct SurveyQuestionsView: View {
    let template: SurveyTemplateType
    let surveyTitle: String
    let surveyDescription: String
    let minResponses: Int
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var questions: [QuestionItem] = []
    @State private var showingAddQuestion = false
    @State private var isCreatingSurvey = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccessView = false
    @State private var createdSurvey: Survey?
    
    var body: some View {
        ZStack {
            VStack {
                if questions.isEmpty {
                    emptyStateView
                } else {
                    questionsList
                }
                
                // Bottom bar with button
                VStack(spacing: 16) {
                    if questions.count < 10 {
                        Button {
                            showingAddQuestion = true
                        } label: {
                            Label("Add Question", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.teal.opacity(0.1))
                                .foregroundColor(.teal)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button {
                        createSurvey()
                    } label: {
                        if isCreatingSurvey {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Survey")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(questions.count >= 3 ? Color.teal : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(questions.count < 3 || isCreatingSurvey)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
        }
        .navigationTitle("Survey Questions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if questions.count < 10 {
                    Button {
                        showingAddQuestion = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            loadTemplateQuestions()
        }
        .sheet(isPresented: $showingAddQuestion) {
            AddQuestionView { question in
                questions.append(question)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showSuccessView) {
            if let survey = createdSurvey {
                SurveyCreatedSuccessView(survey: survey)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "questionmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No questions yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add questions to create your survey")
                .foregroundColor(.secondary)
            
            Text("Minimum 3 questions • Maximum 10 questions")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    private var questionsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    QuestionCard(
                        question: question,
                        index: index + 1,
                        onDelete: {
                            questions.remove(at: index)
                        },
                        onMoveUp: index > 0 ? {
                            questions.swapAt(index, index - 1)
                        } : nil,
                        onMoveDown: index < questions.count - 1 ? {
                            questions.swapAt(index, index + 1)
                        } : nil
                    )
                }
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("\(questions.count)/10 questions")
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding()
            .padding(.bottom, 120)
        }
    }
    
    private func loadTemplateQuestions() {
        // Load default questions based on template
        switch template {
        case .individual:
            questions = [
                QuestionItem(
                    type: .rating,
                    prompt: "How would you rate my overall performance?",
                    minValue: 1,
                    maxValue: 5,
                    minLabel: "Needs improvement",
                    maxLabel: "Excellent"
                ),
                QuestionItem(
                    type: .text,
                    prompt: "What are my greatest strengths?"
                ),
                QuestionItem(
                    type: .text,
                    prompt: "What areas should I focus on improving?"
                )
            ]
        case .team:
            questions = [
                QuestionItem(
                    type: .rating,
                    prompt: "How well does our team collaborate?",
                    minValue: 1,
                    maxValue: 5,
                    minLabel: "Poorly",
                    maxLabel: "Excellently"
                ),
                QuestionItem(
                    type: .multipleChoice,
                    prompt: "What best describes our team communication?",
                    choices: ["Very clear", "Mostly clear", "Sometimes unclear", "Often confusing"]
                ),
                QuestionItem(
                    type: .text,
                    prompt: "What could improve our team dynamics?"
                )
            ]
        case .product:
            questions = [
                QuestionItem(
                    type: .rating,
                    prompt: "How satisfied are you with the product?",
                    minValue: 1,
                    maxValue: 5,
                    minLabel: "Very dissatisfied",
                    maxLabel: "Very satisfied"
                ),
                QuestionItem(
                    type: .multipleChoice,
                    prompt: "How often do you use the product?",
                    choices: ["Daily", "Weekly", "Monthly", "Rarely"]
                ),
                QuestionItem(
                    type: .text,
                    prompt: "What features would you like to see added?"
                )
            ]
        case .service:
            questions = [
                QuestionItem(
                    type: .rating,
                    prompt: "How would you rate the service quality?",
                    minValue: 1,
                    maxValue: 5,
                    minLabel: "Poor",
                    maxLabel: "Excellent"
                ),
                QuestionItem(
                    type: .yesNo,
                    prompt: "Would you recommend our service to others?"
                ),
                QuestionItem(
                    type: .text,
                    prompt: "How can we improve our service?"
                )
            ]
        case .custom:
            questions = []
        }
    }
    
    private func createSurvey() {
        guard questions.count >= 3 else {
            errorMessage = "Please add at least 3 questions"
            showError = true
            return
        }
        
        isCreatingSurvey = true
        
        // Create mock survey for now
        let survey = Survey(
            id: UUID().uuidString,
            userId: authManager.currentUser?.id ?? "",
            templateType: template,
            minResponses: minResponses,
            urlToken: UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased().prefix(22).lowercased(),
            createdAt: Date(),
            title: surveyTitle,
            description: surveyDescription.isEmpty ? nil : surveyDescription,
            questions: questions.enumerated().map { index, item in
                Question(
                    id: UUID().uuidString,
                    surveyId: "",
                    order: index,
                    type: item.type,
                    prompt: item.prompt,
                    isRequired: true,
                    choices: item.choices,
                    minValue: item.minValue,
                    maxValue: item.maxValue,
                    minLabel: item.minLabel,
                    maxLabel: item.maxLabel
                )
            }
        )
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCreatingSurvey = false
            createdSurvey = survey
            showSuccessView = true
        }
    }
}

// Helper struct for question creation
struct QuestionItem {
    let id = UUID()
    let type: QuestionType
    let prompt: String
    var choices: [String]? = nil
    var minValue: Int? = nil
    var maxValue: Int? = nil
    var minLabel: String? = nil
    var maxLabel: String? = nil
}

struct QuestionCard: View {
    let question: QuestionItem
    let index: Int
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Question \(index)", systemImage: question.type.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    if let onMoveUp = onMoveUp {
                        Button {
                            withAnimation {
                                onMoveUp()
                            }
                        } label: {
                            Label("Move Up", systemImage: "arrow.up")
                        }
                    }
                    
                    if let onMoveDown = onMoveDown {
                        Button {
                            withAnimation {
                                onMoveDown()
                            }
                        } label: {
                            Label("Move Down", systemImage: "arrow.down")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        withAnimation {
                            onDelete()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(question.prompt)
                .font(.body)
            
            // Preview of answer type
            Group {
                switch question.type {
                case .multipleChoice:
                    if let choices = question.choices {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(choices, id: \.self) { choice in
                                HStack(spacing: 8) {
                                    Image(systemName: "circle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(choice)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                case .rating:
                    HStack {
                        if let minLabel = question.minLabel {
                            Text(minLabel)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { _ in
                                Image(systemName: "star")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let maxLabel = question.maxLabel {
                            Text(maxLabel)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                case .text:
                    Text("Open text response")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                case .yesNo:
                    HStack(spacing: 12) {
                        Text("Yes")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                        
                        Text("No")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SurveyQuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SurveyQuestionsView(
                template: .individual,
                surveyTitle: "Q4 Performance Review",
                surveyDescription: "Help me understand my performance",
                minResponses: 10
            )
            .environmentObject(AuthManager())
        }
    }
} 