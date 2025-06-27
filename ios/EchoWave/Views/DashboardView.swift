import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var activeSurveys = 0
    @State private var totalResponses = 0
    @State private var currentStreak = 7
    @State private var userLevel = 2
    @State private var userPoints = 450
    @State private var nextLevelPoints = 500
    @State private var recentActivity: [ActivityItem] = []
    @State private var showingLevelUp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with gamification
                    headerSection
                    
                    // Quick stats
                    statsSection
                    
                    // Progress to next level
                    progressSection
                    
                    // Recent achievements
                    achievementsSection
                    
                    // Recent activity
                    activitySection
                    
                    // Quick actions
                    quickActionsSection
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                loadDashboardData()
            }
            .sheet(isPresented: $showingLevelUp) {
                LevelUpView(newLevel: userLevel)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.teal)
                        
                        Text(authManager.currentUser?.displayName ?? "User")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Level badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("Level \(userLevel)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
                
                // Streak indicator
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 0) {
                            Image(systemName: "flame.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            Text("\(currentStreak)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Active Surveys",
                value: "\(activeSurveys)",
                icon: "doc.text.fill",
                color: .teal,
                trend: "+2 this week"
            )
            
            StatCard(
                title: "Total Responses",
                value: "\(totalResponses)",
                icon: "person.3.fill",
                color: .blue,
                trend: "+15 this month"
            )
        }
        .padding(.horizontal)
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress to Level \(userLevel + 1)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(userPoints)/\(nextLevelPoints) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color.teal, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * CGFloat(userPoints) / CGFloat(nextLevelPoints), height: 12)
                        .animation(.spring(), value: userPoints)
                }
            }
            .frame(height: 12)
            
            Text("Complete surveys and collect feedback to earn XP")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: Text("All Achievements")) {
                    Text("See all")
                        .font(.caption)
                        .foregroundColor(.teal)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    AchievementBadge(
                        icon: "star.fill",
                        title: "First Survey",
                        subtitle: "Created your first survey",
                        color: .yellow,
                        isUnlocked: true
                    )
                    
                    AchievementBadge(
                        icon: "person.3.fill",
                        title: "Popular",
                        subtitle: "10+ responses on a survey",
                        color: .purple,
                        isUnlocked: true
                    )
                    
                    AchievementBadge(
                        icon: "flame.fill",
                        title: "On Fire",
                        subtitle: "7 day streak",
                        color: .orange,
                        isUnlocked: true
                    )
                    
                    AchievementBadge(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Analyst",
                        subtitle: "View 5 survey results",
                        color: .green,
                        isUnlocked: false
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            if recentActivity.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 120)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("No recent activity")
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentActivity) { activity in
                        ActivityRow(activity: activity)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: CreateSurveyView()) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Create New Survey",
                    subtitle: "Start collecting feedback",
                    color: .teal
                )
            }
            
            NavigationLink(destination: SurveysListView()) {
                QuickActionCard(
                    icon: "chart.bar.fill",
                    title: "View Results",
                    subtitle: "See your survey insights",
                    color: .blue
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func loadDashboardData() {
        // Mock data - in production, this would be API calls
        activeSurveys = 3
        totalResponses = 42
        currentStreak = authManager.currentUser?.streakDays ?? 7
        userLevel = authManager.currentUser?.level ?? 2
        userPoints = authManager.currentUser?.points ?? 450
        
        recentActivity = [
            ActivityItem(
                id: "1",
                icon: "person.3.fill",
                title: "New response received",
                subtitle: "Q4 Performance Review",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            ActivityItem(
                id: "2",
                icon: "checkmark.circle.fill",
                title: "Survey completed",
                subtitle: "Team Health Check reached 10 responses",
                timestamp: Date().addingTimeInterval(-7200)
            ),
            ActivityItem(
                id: "3",
                icon: "star.fill",
                title: "Achievement unlocked",
                subtitle: "Popular - 10+ responses",
                timestamp: Date().addingTimeInterval(-86400)
            )
        ]
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Text(trend)
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? color : .gray)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isUnlocked ? .primary : .gray)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .opacity(isUnlocked ? 1 : 0.6)
    }
}

struct ActivityItem: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let timestamp: Date
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(.teal)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct LevelUpView: View {
    let newLevel: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "star.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.yellow)
            
            Text("Level Up!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You've reached Level \(newLevel)")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Keep collecting feedback to unlock more features!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Awesome!")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AuthManager())
    }
} 