import Foundation

struct Survey: Codable, Identifiable {
    let id: String
    let userId: String
    let templateType: SurveyTemplateType
    let minResponses: Int
    let urlToken: String
    let createdAt: Date
    
    var title: String
    var description: String?
    var questions: [Question]
    var responseCount: Int = 0
    var isActive: Bool = true
    var summary: SurveySummary?
    
    var shareURL: URL {
        // In production, this would be the actual domain
        URL(string: "http://localhost:3000/feedback/\(urlToken)")!
    }
    
    var canViewResults: Bool {
        responseCount >= minResponses
    }
}

enum SurveyTemplateType: String, Codable, CaseIterable {
    case individual = "individual"
    case team = "team"
    case product = "product"
    case service = "service"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .individual: return "Individual Feedback"
        case .team: return "Team Performance"
        case .product: return "Product Review"
        case .service: return "Service Quality"
        case .custom: return "Custom Survey"
        }
    }
    
    var icon: String {
        switch self {
        case .individual: return "person.fill"
        case .team: return "person.3.fill"
        case .product: return "cube.box.fill"
        case .service: return "star.fill"
        case .custom: return "pencil.and.outline"
        }
    }
} 