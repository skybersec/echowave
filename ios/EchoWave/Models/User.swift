import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let createdAt: Date
    var surveys: [Survey] = []
    
    // Profile
    var displayName: String?
    var avatarURL: String?
    
    // Gamification
    var points: Int = 0
    var level: Int = 1
    var streakDays: Int = 0
    var badges: [Badge] = []
}

struct Badge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let earnedAt: Date
} 