import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showAuthView = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.teal.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showAuthView {
                AuthView()
                    .transition(.move(edge: .bottom))
            } else {
                TabView(selection: $currentPage) {
                    OnboardingPage1()
                        .tag(0)
                    
                    OnboardingPage2()
                        .tag(1)
                    
                    OnboardingPage3()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            }
        }
    }
}

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.teal.gradient)
            
            Text("EchoWave")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Hear the candid truth,\ngrow with it.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.teal)
                
                Text("100% Anonymous")
                    .font(.headline)
                
                Text("Feedback is only revealed after 10+ responses to ensure complete anonymity")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundStyle(.teal.gradient)
            
            Text("AI-Powered Insights")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Get actionable feedback with strengths, opportunities, and sentiment analysis")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            // Feature list
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "brain", text: "Smart summarization")
                FeatureRow(icon: "chart.pie.fill", text: "Sentiment analysis")
                FeatureRow(icon: "list.bullet.clipboard", text: "Action plans")
                FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Track progress")
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage3: View {
    @State private var showAuthView = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundStyle(.teal.gradient)
            
            Text("Ready to Grow?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Create your first survey and start collecting candid feedback today")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    showAuthView = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.teal)
                        .cornerRadius(12)
                }
                
                Text("Free for your first survey")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $showAuthView) {
            AuthView()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.teal)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
        }
    }
} 