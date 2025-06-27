import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile - Coming Soon")
                
                Button {
                    authManager.signOut()
                } label: {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
    }
} 