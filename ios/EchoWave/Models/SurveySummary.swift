import Foundation

struct SurveySummary: Codable, Identifiable {
    let id: String
    let surveyId: String
    let gptModel: String
    let createdAt: Date
    
    // AI-generated insights
    let strengths: [String]
    let opportunities: [String]
    let overallSentiment: Sentiment
    let sentimentScore: Double // -1.0 to 1.0
    let keyThemes: [String]
    let actionableInsights: [ActionableInsight]
    
    // Raw summary text
    let rawSummary: String
}

struct ActionableInsight: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: Priority
    let category: String
    
    enum Priority: String, Codable {
        case high, medium, low
        
        var color: String {
            switch self {
            case .high: return "red"
            case .medium: return "orange"
            case .low: return "green"
            }
        }
    }
}

enum Sentiment: String, Codable {
    case veryPositive = "very_positive"
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    case veryNegative = "very_negative"
    
    var emoji: String {
        switch self {
        case .veryPositive: return "😊"
        case .positive: return "🙂"
        case .neutral: return "😐"
        case .negative: return "😕"
        case .veryNegative: return "😞"
        }
    }
    
    var color: String {
        switch self {
        case .veryPositive: return "green"
        case .positive: return "mint"
        case .neutral: return "gray"
        case .negative: return "orange"
        case .veryNegative: return "red"
        }
    }
} 