import Foundation

struct Response: Codable, Identifiable {
    let id: String
    let surveyId: String
    let submittedAt: Date
    var answers: [Answer]
}

struct Answer: Codable, Identifiable {
    let id: String
    let responseId: String
    let questionId: String
    let value: String
} 