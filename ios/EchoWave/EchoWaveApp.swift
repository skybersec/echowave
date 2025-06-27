import SwiftUI

@main
struct EchoWaveApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var networkManager = NetworkManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(networkManager)
                .preferredColorScheme(.light)
        }
    }
} 