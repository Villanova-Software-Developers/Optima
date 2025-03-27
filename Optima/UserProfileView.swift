import SwiftUI
import FirebaseAuth

// MARK: - Models
struct UserProfile {
    var id: String
    var username: String
    var email: String
    var totalPoints: Int
    var currentStreak: Int
    var joinDate: Date
    var achievements: [Achievement]
    var preferences: UserPreferences
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    var isUnlocked: Bool
    var unlockedDate: Date?
}

struct UserPreferences {
    var isDarkMode: Bool
    var notificationsEnabled: Bool
    var dailyScreenTimeLimit: TimeInterval
    var isProfilePublic: Bool
}

struct UserStats {
    var tasksCompleted: Int
    var totalScreenTimeSaved: TimeInterval
    var averageProductivity: Double
    var longestStreak: Int
}

// MARK: - View Model
class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var stats: UserStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadUserProfile()
    }
    
    
    private func loadUserProfile() {
        isLoading = true
        let userId = UserDefaults.standard.string(forKey: "userId") ?? "Default UserID"
        let username = UserDefaults.standard.string(forKey: "username") ?? "Default Username"
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? "Default Email"
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Sample data
            self.profile = UserProfile(
                id: userId,
                username: username,
                email: email,
                totalPoints: 1250,
                currentStreak: 7,
                joinDate: Date().addingTimeInterval(-30*24*3600),
                achievements: [
                    Achievement(title: "Early Bird", description: "Complete 5 tasks before 9 AM", iconName: "sunrise.fill", isUnlocked: true, unlockedDate: Date()),
                    Achievement(title: "Streak Master", description: "Maintain a 7-day streak", iconName: "flame.fill", isUnlocked: true, unlockedDate: Date()),
                    Achievement(title: "Digital Detox", description: "Save 24 hours of screen time", iconName: "timer", isUnlocked: false)
                ],
                preferences: UserPreferences(
                    isDarkMode: false,
                    notificationsEnabled: true,
                    dailyScreenTimeLimit: 4 * 3600,
                    isProfilePublic: true
                )
            )
            
            self.stats = UserStats(
                tasksCompleted: 145,
                totalScreenTimeSaved: 72 * 3600,
                averageProductivity: 0.85,
                longestStreak: 14
            )
            
            self.isLoading = false
        }
    }
   

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Views
struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var showingSettingsSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let profile = viewModel.profile {
                    VStack(spacing: 20) {
                        ProfileHeaderView(profile: profile)
                        StatsGridView(stats: viewModel.stats)
                        AchievementsView(achievements: profile.achievements)
                        ActivitySummaryView()
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                Button(action: { showingSettingsSheet = true }) {
                    Image(systemName: "gear")
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView(viewModel: viewModel)
            }
        }
    }
}

struct ProfileHeaderView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(AppTheme.accent)
                .background(Circle().fill(AppTheme.accent.opacity(0.1)))
            
            // User Info
            VStack(spacing: 8) {
                Text(profile.username)
                    .font(.title2)
                    .bold()
                
                Text(profile.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Quick Stats
            HStack(spacing: 40) {
                StatView(value: "\(profile.totalPoints)", title: "Points")
                StatView(value: "\(profile.currentStreak)", title: "Day Streak")
                StatView(value: "Lvl \(profile.totalPoints/100)", title: "Level")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(0)
        .shadow(radius: 0)
    }
}

struct StatView: View {
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatsGridView: View {
    let stats: UserStats?
    
    var body: some View {
        if let stats = stats {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Tasks Completed",
                    value: "\(stats.tasksCompleted)",
                    icon: "checkmark.circle.fill"
                )
                
                StatCard(
                    title: "Screen Time Saved",
                    value: "\(Int(stats.totalScreenTimeSaved/3600))h",
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Productivity",
                    value: "\(Int(stats.averageProductivity * 100))%",
                    icon: "chart.bar.fill"
                )
                
                StatCard(
                    title: "Longest Streak",
                    value: "\(stats.longestStreak) days",
                    icon: "flame.fill"
    
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.accent)
            Text(value)
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AchievementsView: View {
    let achievements: [Achievement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.iconName)
                .font(.title)
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
            
            Text(achievement.title)
                .font(.subheadline)
                .bold()
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let date = achievement.unlockedDate {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 150)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .opacity(achievement.isUnlocked ? 1 : 0.6)
    }
}

struct ActivitySummaryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Summary")
                .font(.headline)
            
            // Add your activity chart here
            Rectangle()
                .fill(Color.blue.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Activity Chart")
                        .foregroundColor(.secondary)
                )
                .cornerRadius(12)
        }
    }
}

// In your SettingsView file, add/update this section
struct SettingsView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @EnvironmentObject var authManager: AuthStateManager // Add this line
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                if let profile = viewModel.profile {
                    // Your existing sections...
                    
                    Section {
                        Button("Sign Out", role: .destructive) {
                            showingSignOutAlert = true
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // Add the logout function here
    func logout() {
        // Clear all authentication data
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "userId")
        
        // Update authentication state
        authManager.isAuthenticated = false
        
        // Sign out from Firebase (if used)
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
        
        // Dismiss this view and return to auth flow
        dismiss()
    }
}
#Preview {
    UserProfileView()
}
