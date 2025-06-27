import Foundation

struct Question: Codable, Identifiable {
    let id: String
    let surveyId: String
    let order: Int
    let type: QuestionType
    let prompt: String
    let isRequired: Bool
    
    // For multiple choice questions
    var choices: [String]?
    
    // For rating questions
    var minValue: Int?
    var maxValue: Int?
    var minLabel: String?
    var maxLabel: String?
}

enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case text = "text"
    case rating = "rating"
    case yesNo = "yes_no"
    
    var icon: String {
        switch self {
        case .multipleChoice: return "list.bullet"
        case .text: return "text.alignleft"
        case .rating: return "star.fill"
        case .yesNo: return "checkmark.circle"
        }
    }
} 