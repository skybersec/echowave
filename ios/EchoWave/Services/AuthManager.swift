import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private let keychain = KeychainManager()
    private let userDefaults = UserDefaults.standard
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let token = keychain.getToken() {
            self.authToken = token
            self.isAuthenticated = true
            // In production, validate token with backend
            loadUserProfile()
        }
    }
    
    func signIn(email: String, password: String) async throws {
        // TODO: Implement actual API call
        // For now, mock authentication
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        let mockUser = User(
            id: UUID().uuidString,
            email: email,
            createdAt: Date(),
            displayName: email.components(separatedBy: "@").first
        )
        
        let mockToken = UUID().uuidString
        
        await MainActor.run {
            self.currentUser = mockUser
            self.authToken = mockToken
            self.isAuthenticated = true
        }
        
        keychain.saveToken(mockToken)
        saveUserToDefaults(mockUser)
    }
    
    func signUp(email: String, password: String) async throws {
        // TODO: Implement actual API call
        try await signIn(email: email, password: password)
    }
    
    func signOut() {
        keychain.deleteToken()
        userDefaults.removeObject(forKey: "currentUser")
        
        currentUser = nil
        authToken = nil
        isAuthenticated = false
    }
    
    private func loadUserProfile() {
        if let userData = userDefaults.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
    }
    
    private func saveUserToDefaults(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: "currentUser")
        }
    }
} 