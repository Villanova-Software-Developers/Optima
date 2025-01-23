import SwiftUI

// MARK: - Models
struct Task: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var category: TaskCategory
    var duration: TimeInterval
    var points: Int
    var isCompleted: Bool = false
}

enum TaskCategory: String, CaseIterable {
    case academic = "Academic"
    case fitness = "Fitness"
    case household = "Household"
    case wellness = "Wellness"
    case custom = "Custom"
}

// MARK: - View Models
class UserViewModel: ObservableObject {
    @Published var screenTimeAllowance: TimeInterval
    @Published var points: Int = 0
    @Published var currentStreak: Int = 0
    @Published var tasks: [Task] = []
    
    init(initialScreenTime: TimeInterval = 4 * 3600) { // 4 hours default
        self.screenTimeAllowance = initialScreenTime
    }
    
    func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            points += task.points
            updateScreenTime(earned: task.duration)
        }
    }
    
    private func updateScreenTime(earned: TimeInterval) {
        screenTimeAllowance += earned
    }
}

// MARK: - Main Views
struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: userViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            TasksView(viewModel: userViewModel)
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(1)
            
            ProfileView(viewModel: userViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ScreenTimeCard(allowance: viewModel.screenTimeAllowance)
                    
                    StreakCard(streak: viewModel.currentStreak)
                    
                    TaskProgressCard(completedTasks: viewModel.tasks.filter { $0.isCompleted }.count,
                                   totalTasks: viewModel.tasks.count)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Tasks View
struct TasksView: View {
    @ObservedObject var viewModel: UserViewModel
    @State private var showingNewTaskSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(viewModel.tasks.filter { $0.category == category }) { task in
                            TaskRow(task: task) {
                                viewModel.completeTask(task)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                Button(action: { showingNewTaskSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingNewTaskSheet) {
                NewTaskView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Supporting Views
struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        VStack {
            Text("Current Streak")
                .font(.headline)
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(streak) days")
                    .font(.title)
                    .bold()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
}

struct TaskProgressCard: View {
    let completedTasks: Int
    let totalTasks: Int
    
    var body: some View {
        VStack {
            Text("Task Progress")
                .font(.headline)
            Text("\(completedTasks)/\(totalTasks)")
                .font(.title)
                .bold()
            ProgressView(value: Double(completedTasks), total: Double(totalTasks))
                .tint(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
}


struct ScreenTimeCard: View {
    let allowance: TimeInterval
    
    var body: some View {
        VStack {
            Text("Screen Time Available")
                .font(.headline)
            Text(timeString(from: allowance))
                .font(.largeTitle)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

struct TaskRow: View {
    let task: Task
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !task.isCompleted {
                Button(action: onComplete) {
                    Text("+\(task.points)")
                        .padding(8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .opacity(task.isCompleted ? 0.6 : 1)
    }
}





// MARK: - New Task View
struct NewTaskView: View {
    @ObservedObject var viewModel: UserViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = TaskCategory.custom
    @State private var duration: Double = 30 // minutes
    @State private var points = 10
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Duration & Points")) {
                    Stepper("Duration: \(Int(duration)) minutes", value: $duration, in: 5...180, step: 5)
                    Stepper("Points: \(points)", value: $points, in: 5...50, step: 5)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveTask() {
        let newTask = Task(
            title: title,
            description: description,
            category: selectedCategory,
            duration: duration * 60, // Convert to seconds
            points: points
        )
        viewModel.tasks.append(newTask)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @ObservedObject var viewModel: UserViewModel
    @State private var showingSettingsSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ProfileHeaderView(viewModel: viewModel)
                    
                    AchievementsView(viewModel: viewModel)
                    
                    StatisticsView(viewModel: viewModel)
                    
                    SocialFeedView(viewModel: viewModel)
                }
                .padding()
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

// MARK: - Profile Supporting Views
struct ProfileHeaderView: View {
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
            
            Text(viewModel.userName)
                .font(.title2)
                .bold()
            
            HStack(spacing: 20) {
                StatCard(title: "Points", value: "\(viewModel.points)")
                StatCard(title: "Streak", value: "\(viewModel.currentStreak) days")
                StatCard(title: "Level", value: "\(viewModel.currentLevel)")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .bold()
        }
        .frame(minWidth: 80)
    }
}

struct AchievementsView: View {
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.title3)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.achievements) { achievement in
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
        VStack {
            Image(systemName: achievement.iconName)
                .font(.largeTitle)
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
            
            Text(achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 100)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatisticsView: View {
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.title3)
                .bold()
            
            VStack(spacing: 15) {
                ProgressRow(title: "Weekly Goal", progress: viewModel.weeklyProgress)
                ProgressRow(title: "Monthly Goal", progress: viewModel.monthlyProgress)
                ProgressRow(title: "Screen Time Reduction", progress: viewModel.screenTimeReductionProgress)
            }
        }
    }
}

struct ProgressRow: View {
    let title: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}

struct SocialFeedView: View {
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Feed")
                .font(.title3)
                .bold()
            
            ForEach(viewModel.socialFeed) { post in
                SocialPostCard(post: post)
            }
        }
    }
}

struct SocialPostCard: View {
    let post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle")
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(post.userName)
                        .font(.headline)
                    Text(post.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(post.content)
                .font(.body)
            
            HStack {
                Button(action: {}) {
                    Label("\(post.likes)", systemImage: "heart")
                }
                
                Spacer()
                
                Button(action: {}) {
                    Label("Comment", systemImage: "message")
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: UserViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    TextField("Name", text: $viewModel.userName)
                    Toggle("Public Profile", isOn: $viewModel.isProfilePublic)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Task Reminders", isOn: $viewModel.taskReminders)
                    Toggle("Streak Alerts", isOn: $viewModel.streakAlerts)
                    Toggle("Achievement Alerts", isOn: $viewModel.achievementAlerts)
                }
                
                Section(header: Text("Screen Time")) {
                    Stepper(
                        "Daily Limit: \(Int(viewModel.screenTimeAllowance/3600)) hours",
                        value: $viewModel.screenTimeAllowance,
                        in: 1800...28800,
                        step: 1800
                    )
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Additional Models
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    var isUnlocked: Bool
}

struct SocialPost: Identifiable {
    let id = UUID()
    let userName: String
    let content: String
    let timestamp: Date
    var likes: Int
}

// MARK: - ViewModel Extensions
extension UserViewModel {
    var userName: String {
        get { UserDefaults.standard.string(for: .userName) ?? "User" }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.userName.rawValue) }
    }
    
    var isProfilePublic: Bool {
        get { UserDefaults.standard.bool(for: .isProfilePublic) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.isProfilePublic.rawValue) }
    }
    
    var taskReminders: Bool {
        get { UserDefaults.standard.bool(for: .taskReminders) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.taskReminders.rawValue) }
    }
    
    var streakAlerts: Bool {
        get { UserDefaults.standard.bool(for: .streakAlerts) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.streakAlerts.rawValue) }
    }
    
    var achievementAlerts: Bool {
        get { UserDefaults.standard.bool(for: .achievementAlerts) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.achievementAlerts.rawValue) }
    }
    
    var currentLevel: Int {
        max(1, points / 100)
    }
    
    var weeklyProgress: Double {
        0.7 // Replace with actual calculation
    }
    
    var monthlyProgress: Double {
        0.5 // Replace with actual calculation
    }
    
    var screenTimeReductionProgress: Double {
        0.3 // Replace with actual calculation
    }
    
    var achievements: [Achievement] {
        [
            Achievement(title: "First Task", iconName: "star.fill", isUnlocked: true),
            Achievement(title: "7-Day Streak", iconName: "flame.fill", isUnlocked: true),
            Achievement(title: "Screen Master", iconName: "iphone", isUnlocked: false)
        ]
    }
    
    var socialFeed: [SocialPost] {
        [
            SocialPost(userName: "Sarah", content: "Completed my daily fitness goal! 🏃‍♀️", timestamp: Date(), likes: 5),
            SocialPost(userName: "Mike", content: "30-day streak! 🔥", timestamp: Date().addingTimeInterval(-3600), likes: 12)
        ]
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    enum Key: String {
        case userName
        case isProfilePublic
        case taskReminders
        case streakAlerts
        case achievementAlerts
    }
    
    func bool(for key: Key) -> Bool {
        bool(forKey: key.rawValue)
    }
    
    func string(for key: Key) -> String? {
        string(forKey: key.rawValue)
    }
}

#Preview {
    ContentView()
}
