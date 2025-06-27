import SwiftUI

struct CreateSurveyView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTemplate = SurveyTemplateType.individual
    @State private var surveyTitle = ""
    @State private var surveyDescription = ""
    @State private var minResponses = 10
    @State private var showingTemplateSelector = false
    @State private var navigateToQuestions = false
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Template Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Survey Type", systemImage: "doc.text")
                            .font(.headline)
                        
                        Button {
                            showingTemplateSelector = true
                        } label: {
                            HStack {
                                Image(systemName: selectedTemplate.icon)
                                    .foregroundColor(.teal)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedTemplate.displayName)
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    
                                    Text(templateDescription(for: selectedTemplate))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Survey Details
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Survey Details", systemImage: "pencil")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g., Q4 Performance Review", text: $surveyTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (optional)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $surveyDescription)
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Anonymity Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Anonymity Settings", systemImage: "lock.shield")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Minimum responses for results")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Picker("", selection: $minResponses) {
                                    ForEach([10, 15, 20, 25, 30], id: \.self) { num in
                                        Text("\(num)").tag(num)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(.teal)
                            }
                            
                            Text("Results will only be shown after \(minResponses) people respond")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.teal.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Info Card
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy First")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("All responses are anonymous. Respondents cannot be identified.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Continue Button
                    NavigationLink(destination: SurveyQuestionsView(
                        template: selectedTemplate,
                        surveyTitle: surveyTitle,
                        surveyDescription: surveyDescription,
                        minResponses: minResponses
                    ), isActive: $navigateToQuestions) {
                        EmptyView()
                    }
                    
                    Button {
                        if validateForm() {
                            navigateToQuestions = true
                        }
                    } label: {
                        HStack {
                            Text("Continue to Questions")
                                .fontWeight(.semibold)
                            
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(surveyTitle.isEmpty ? Color.gray : Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(surveyTitle.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Create Survey")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTemplateSelector) {
                TemplateSelectorView(selectedTemplate: $selectedTemplate)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func validateForm() -> Bool {
        if surveyTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter a survey title"
            showError = true
            return false
        }
        
        if surveyTitle.count < 3 {
            errorMessage = "Survey title must be at least 3 characters"
            showError = true
            return false
        }
        
        return true
    }
    
    private func templateDescription(for template: SurveyTemplateType) -> String {
        switch template {
        case .individual:
            return "Personal growth and performance feedback"
        case .team:
            return "Team dynamics and collaboration feedback"
        case .product:
            return "Product experience and feature feedback"
        case .service:
            return "Service quality and customer satisfaction"
        case .custom:
            return "Build your own custom survey"
        }
    }
}

struct TemplateSelectorView: View {
    @Binding var selectedTemplate: SurveyTemplateType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(SurveyTemplateType.allCases, id: \.self) { template in
                Button {
                    selectedTemplate = template
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: template.icon)
                            .font(.title2)
                            .foregroundColor(.teal)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.displayName)
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                            
                            Text(templateDescription(for: template))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if template == selectedTemplate {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.teal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Choose Template")
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
    
    private func templateDescription(for template: SurveyTemplateType) -> String {
        switch template {
        case .individual:
            return "Get feedback on personal performance, skills, and growth areas"
        case .team:
            return "Understand team dynamics, collaboration, and work environment"
        case .product:
            return "Collect user feedback on product features and experience"
        case .service:
            return "Measure service quality and customer satisfaction"
        case .custom:
            return "Create a completely custom survey from scratch"
        }
    }
}

struct CreateSurveyView_Previews: PreviewProvider {
    static var previews: some View {
        CreateSurveyView()
            .environmentObject(AuthManager())
    }
} 