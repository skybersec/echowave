import SwiftUI

struct AddQuestionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedType = QuestionType.text
    @State private var questionPrompt = ""
    @State private var choices: [String] = ["", "", "", ""]
    @State private var minValue = 1
    @State private var maxValue = 5
    @State private var minLabel = ""
    @State private var maxLabel = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onAdd: (QuestionItem) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Question Type", selection: $selectedType) {
                        ForEach([QuestionType.text, .multipleChoice, .rating, .yesNo], id: \.self) { type in
                            Label(typeDisplayName(type), systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Question") {
                    TextField("Enter your question", text: $questionPrompt, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Type-specific options
                switch selectedType {
                case .multipleChoice:
                    Section("Choices") {
                        ForEach(0..<4) { index in
                            HStack {
                                Text("Option \(index + 1)")
                                    .frame(width: 70)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter choice", text: $choices[index])
                            }
                        }
                    }
                    
                case .rating:
                    Section("Rating Scale") {
                        HStack {
                            Text("Scale")
                            Spacer()
                            Text("\(minValue) to \(maxValue)")
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Low label (optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g., Strongly disagree", text: $minLabel)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("High label (optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g., Strongly agree", text: $maxLabel)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                case .text, .yesNo:
                    EmptyView()
                }
                
                // Preview
                Section("Preview") {
                    QuestionPreview(
                        type: selectedType,
                        prompt: questionPrompt.isEmpty ? "Your question will appear here" : questionPrompt,
                        choices: selectedType == .multipleChoice ? choices.filter { !$0.isEmpty } : nil,
                        minLabel: minLabel.isEmpty ? nil : minLabel,
                        maxLabel: maxLabel.isEmpty ? nil : maxLabel
                    )
                }
            }
            .navigationTitle("Add Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if validateQuestion() {
                            addQuestion()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(questionPrompt.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func typeDisplayName(_ type: QuestionType) -> String {
        switch type {
        case .text: return "Text"
        case .multipleChoice: return "Multiple"
        case .rating: return "Rating"
        case .yesNo: return "Yes/No"
        }
    }
    
    private func validateQuestion() -> Bool {
        if questionPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter a question"
            showError = true
            return false
        }
        
        if selectedType == .multipleChoice {
            let validChoices = choices.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if validChoices.count < 2 {
                errorMessage = "Please provide at least 2 choices"
                showError = true
                return false
            }
        }
        
        return true
    }
    
    private func addQuestion() {
        let question = QuestionItem(
            type: selectedType,
            prompt: questionPrompt,
            choices: selectedType == .multipleChoice ? choices.filter { !$0.isEmpty } : nil,
            minValue: selectedType == .rating ? minValue : nil,
            maxValue: selectedType == .rating ? maxValue : nil,
            minLabel: selectedType == .rating && !minLabel.isEmpty ? minLabel : nil,
            maxLabel: selectedType == .rating && !maxLabel.isEmpty ? maxLabel : nil
        )
        
        onAdd(question)
        dismiss()
    }
}

struct QuestionPreview: View {
    let type: QuestionType
    let prompt: String
    let choices: [String]?
    let minLabel: String?
    let maxLabel: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.body)
                .foregroundColor(prompt == "Your question will appear here" ? .secondary : .primary)
            
            switch type {
            case .text:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 80)
                    .overlay(
                        Text("Text response area")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
                
            case .multipleChoice:
                if let choices = choices, !choices.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(choices, id: \.self) { choice in
                            HStack(spacing: 12) {
                                Image(systemName: "circle")
                                Text(choice)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Add choices above")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
            case .rating:
                VStack(spacing: 8) {
                    HStack {
                        ForEach(1...5, id: \.self) { rating in
                            Image(systemName: "star")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if minLabel != nil || maxLabel != nil {
                        HStack {
                            Text(minLabel ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(maxLabel ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
            case .yesNo:
                HStack(spacing: 20) {
                    Button { } label: {
                        Text("Yes")
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Button { } label: {
                        Text("No")
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .disabled(true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AddQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        AddQuestionView { _ in }
    }
} 