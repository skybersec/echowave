import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.teal.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.teal.gradient)
                    
                    Text("EchoWave")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Email", systemImage: "envelope")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("your@email.com", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Password", systemImage: "lock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Confirm password (sign up only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Confirm Password", systemImage: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action button
                    Button {
                        handleAuth()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isLoading)
                    
                    // Toggle sign up/sign in
                    Button {
                        withAnimation {
                            isSignUp.toggle()
                            clearForm()
                        }
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundColor(.teal)
                    }
                    
                    // Social auth options
                    VStack(spacing: 16) {
                        Text("or continue with")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            SocialAuthButton(provider: "Google", icon: "g.circle.fill")
                            SocialAuthButton(provider: "Facebook", icon: "f.circle.fill")
                            SocialAuthButton(provider: "Instagram", icon: "camera.circle.fill")
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAuth() {
        guard validateForm() else { return }
        
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func validateForm() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields"
            showError = true
            return false
        }
        
        if !email.contains("@") {
            errorMessage = "Please enter a valid email"
            showError = true
            return false
        }
        
        if isSignUp && password != confirmPassword {
            errorMessage = "Passwords don't match"
            showError = true
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return false
        }
        
        return true
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
    }
}

struct SocialAuthButton: View {
    let provider: String
    let icon: String
    
    var body: some View {
        Button {
            // TODO: Implement social auth
        } label: {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
    }
} 