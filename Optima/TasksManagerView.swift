import SwiftUI
import FirebaseAuth

// MARK: - Models
struct Task: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var description: String
    var category: TaskCategory
    var duration: TimeInterval
    var points: Int
    var isCompleted: Bool = false
    var dueDate: Date?
    var createdDate: Date = Date()

    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}

enum TaskCategory: String, CaseIterable {
    case academic = "Academic"
    case fitness = "Fitness"
    case household = "Household"
    case wellness = "Wellness"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .academic: return "book.fill"
        case .fitness: return "figure.run"
        case .household: return "house.fill"
        case .wellness: return "heart.fill"
        case .custom: return "star.fill"
        }
    }
    
var color: Color {
    switch self {
    case .academic: return AppTheme.primary
    case .fitness: return AppTheme.success
    case .household: return AppTheme.secondary
    case .wellness: return AppTheme.accent
    case .custom: return AppTheme.textSecondary
    }
}
}

// MARK: - View Models
class TaskManagerViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var completedAchievements: [GoalCompletion] = [] // Add this
    @Published var screenTimeAllowance: TimeInterval
    @Published var usedScreenTime: TimeInterval = 0
    @Published var dailyGoal: Int = 3
    @Published var weeklyStreak: Int = 0
    @Published var filterCategory: TaskCategory?
    @Published var sortOption: SortOption = .dueDate
    
    enum SortOption {
        case dueDate
        case category
        case points
    }
    
    init(initialScreenTime: TimeInterval = 4 * 3600) {
        self.screenTimeAllowance = initialScreenTime
        loadTasks()
        startScreenTimeTracking()
    }
    
    var sortedTasks: [Task] {
        var sorted = tasks
        switch sortOption {
        case .dueDate:
            sorted.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .category:
            sorted.sort { $0.category.rawValue < $1.category.rawValue }
        case .points:
            sorted.sort { $0.points > $1.points }
        }
        
        if let filterCategory = filterCategory {
            sorted = sorted.filter { $0.category == filterCategory }
        }
        
        return sorted
    }
    
    var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }
    
    var pendingTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    private func loadTasks() {
        // Sample tasks - in a real app, this would load from persistence
        tasks = [
            Task(title: "Study Mathematics",
                 description: "Complete Chapter 3 exercises",
                 category: .academic,
                 duration: 3600,
                 points: 20,
                 dueDate: Date().addingTimeInterval(24 * 3600)),
            Task(title: "Morning Workout",
                 description: "30 minutes cardio",
                 category: .fitness,
                 duration: 1800,
                 points: 15,
                 dueDate: Date().addingTimeInterval(2 * 3600)),
            Task(title: "Meditation",
                 description: "15 minutes mindfulness",
                 category: .wellness,
                 duration: 900,
                 points: 10,
                 dueDate: Date().addingTimeInterval(6 * 3600))
        ]
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        objectWillChange.send()
    }
    
    func completeTask(_ task: Task) {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].isCompleted = true
                earnScreenTime(task.duration)
                updateStreak()
                
                // Create and add completion to the feed
                let completion = GoalCompletion(
                    userId: Auth.auth().currentUser?.uid ?? "unknown",
                    username: Auth.auth().currentUser?.displayName ?? "User",
                    goalTitle: task.title,
                    description: task.description,
                    duration: Int(task.duration / 60), // Convert seconds to minutes
                    points: task.points,
                    completedAt: Date(),
                    goalType: convertTaskCategory(task.category),
                    likes: 0,
                    comments: []
                )
                
                completedAchievements.insert(completion, at: 0) // Add to beginning of feed
                objectWillChange.send()
            }
        }
    private func convertTaskCategory(_ category: TaskCategory) -> GoalType {
          switch category {
          case .academic: return .study
          case .fitness: return .workout
          case .wellness: return .meditation
          case .household, .custom: return .focus
          }
      }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        objectWillChange.send()
    }
    
    private func earnScreenTime(_ duration: TimeInterval) {
        screenTimeAllowance += duration
        objectWillChange.send()
    }
    
    private func updateStreak() {
        let completedToday = completedTasks.filter {
            Calendar.current.isDate($0.createdDate, inSameDayAs: Date())
        }.count
        
        if completedToday >= dailyGoal {
            weeklyStreak = min(weeklyStreak + 1, 7)
        }
    }
    
    private func startScreenTimeTracking() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.screenTimeAllowance > 0 {
                self.usedScreenTime += 60
                self.screenTimeAllowance -= 60
                self.objectWillChange.send()
            }
        }
    }
}
struct CompletionCelebrationView: View {
    let completion: GoalCompletion
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎉 Achievement Unlocked!")
                .font(.title.bold())
            
            CompletionCard(completion: completion)
                .padding()
            
            Button("Share") {
                // Implement sharing functionality
            }
            .buttonStyle(.borderedProminent)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.plain)
        }
        .padding()
        .onAppear {
            showConfetti = true
        }
    }
}


// Add this celebration sheet that appears when task is completed
struct TaskCompletionCelebrationView: View {
    let task: Task
    @ObservedObject var viewModel: TaskManagerViewModel
    @Binding var showShareSheet: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showAnimation = false
    @State private var additionalComment = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Top decoration
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 30))
                    .foregroundColor(task.category.color)
                    .opacity(showAnimation ? 1 : 0)
                    .offset(y: showAnimation ? 0 : -20)
            }
            .padding(.top, 30)
            
            // Main Certificate
            VStack(spacing: 20) {
                Text("🎉 Achievement Unlocked!")
                    .font(.title2.bold())
                    .foregroundColor(task.category.color)
                    .opacity(showAnimation ? 1 : 0)
                    .offset(y: showAnimation ? 0 : 20)
                
                VStack(spacing: 8) {
                    Image(systemName: task.category.icon)
                        .font(.system(size: 50))
                        .foregroundColor(task.category.color)
                    
                    Text(task.title)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                    
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(task.category.color.opacity(0.1))
                )
                .opacity(showAnimation ? 1 : 0)
                .offset(y: showAnimation ? 0 : 30)
                
                // Stats with earned rewards
                HStack(spacing: 40) {
                    VStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.secondary)
                        Text("\(Int(task.duration/60))m")
                            .font(.headline)
                    }
                    
                    VStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(task.points) pts")
                            .font(.headline)
                    }
                }
                .opacity(showAnimation ? 1 : 0)
                .offset(y: showAnimation ? 0 : 40)
                
                // Optional comment for sharing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a comment (optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Share your thoughts...", text: $additionalComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.top)
                .opacity(showAnimation ? 1 : 0)
                .offset(y: showAnimation ? 0 : 50)
            }
            .padding()
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.shareAchievement(task, withComment: additionalComment)
                    showShareSheet = true
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Achievement")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(task.category.color)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button("Maybe Later") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showAnimation = true
            }
        }
    }
}

extension TaskManagerViewModel {
    func shareAchievement(_ task: Task, withComment comment: String = "") {
        let completion = GoalCompletion(
            userId: Auth.auth().currentUser?.uid ?? "unknown",
            username: Auth.auth().currentUser?.displayName ?? "User",
            goalTitle: task.title,
            description: comment.isEmpty ? task.description : comment,
            duration: Int(task.duration / 60),
            points: task.points,
            completedAt: Date(),
            goalType: convertTaskCategory(task.category),
            likes: 0,
            comments: []
        )
        
        // Add to social feed
        completedAchievements.insert(completion, at: 0)
        objectWillChange.send()
    }
}

// MARK: - Main View
struct TasksManagerView: View {
    @StateObject private var viewModel = TaskManagerViewModel()
    @State private var showingNewTaskSheet = false
    @State private var showingFilters = false
    @State private var showingSort = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Tasks Tab
                ScrollView {
                    VStack(spacing: 20) {
                        ScreenTimeManagerCard(viewModel: viewModel)
                        DailyProgressCard(viewModel: viewModel)
                        TaskCategoriesGrid(viewModel: viewModel)
                        TaskListSection(viewModel: viewModel)
                    }
                    .padding()
                }
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(0)
                
                // Achievements Feed Tab
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.completedAchievements) { completion in
                            CompletionCard(completion: completion)
                                .padding(.horizontal)
                        }
                        
                        if viewModel.completedAchievements.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "trophy.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No achievements yet")
                                    .font(.headline)
                                Text("Complete tasks to share your progress!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .padding(.top, 40)
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGray6))
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }
                .tag(1)
            }
            .navigationTitle(selectedTab == 0 ? "Tasks & Time" : "Achievements")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedTab == 0 {
                        Menu {
                            Picker("Sort By", selection: $viewModel.sortOption) {
                                Text("Due Date").tag(TaskManagerViewModel.SortOption.dueDate)
                                Text("Category").tag(TaskManagerViewModel.SortOption.category)
                                Text("Points").tag(TaskManagerViewModel.SortOption.points)
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == 0 {
                        Button(action: { showingNewTaskSheet = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewTaskSheet) {
                NewTaskView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Supporting Views
struct ScreenTimeManagerCard: View {
    @ObservedObject var viewModel: TaskManagerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Screen Time")
                    .font(.headline)
                Spacer()
                Image(systemName: "clock")
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                HStack {
                    TimeBlock(label: "Available", time: viewModel.screenTimeAllowance)
                    Spacer()
                    TimeBlock(label: "Used Today", time: viewModel.usedScreenTime)
                }
                
                ProgressView(value: viewModel.usedScreenTime,
                           total: viewModel.screenTimeAllowance + viewModel.usedScreenTime)
                    .tint(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TimeBlock: View {
    let label: String
    let time: TimeInterval
    
    var formattedTime: String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formattedTime)
                .font(.title2)
                .bold()
        }
    }
}

struct DailyProgressCard: View {
    @ObservedObject var viewModel: TaskManagerViewModel
    
    var completedToday: Int {
        viewModel.completedTasks.filter {
            Calendar.current.isDate($0.createdDate, inSameDayAs: Date())
        }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Progress")
                    .font(.headline)
                Spacer()
                Text("\(completedToday)/\(viewModel.dailyGoal) Tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                ProgressCircle(
                    progress: Double(completedToday) / Double(viewModel.dailyGoal),
                    color: .blue
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.weeklyStreak) Day Streak")
                            .font(.headline)
                    }
                    
                    Text("Complete \(viewModel.dailyGoal) tasks daily to maintain your streak!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ProgressCircle: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.title3)
                .bold()
        }
        .frame(width: 80, height: 80)
    }
}

struct TaskCategoriesGrid: View {
    @ObservedObject var viewModel: TaskManagerViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(TaskCategory.allCases, id: \.self) { category in
                CategoryCard(
                    category: category,
                    count: viewModel.tasks.filter { $0.category == category }.count,
                    isSelected: viewModel.filterCategory == category
                )
                .onTapGesture {
                    withAnimation {
                        if viewModel.filterCategory == category {
                            viewModel.filterCategory = nil
                        } else {
                            viewModel.filterCategory = category
                        }
                    }
                }
            }
        }
    }
}

struct CategoryCard: View {
    let category: TaskCategory
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.color)
            
            Text(category.rawValue)
                .font(.headline)
            
            Text("\(count) tasks")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
                )
        )
        .shadow(radius: isSelected ? 4 : 2)
    }
}

struct TaskListSection: View {
    @ObservedObject var viewModel: TaskManagerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasks")
                .font(.headline)
            
            if viewModel.sortedTasks.isEmpty {
                EmptyTasksView()
            } else {
                ForEach(viewModel.sortedTasks) { task in
                    TaskRowView(
                        task: task,
                        onComplete: {
                            viewModel.completeTask(task)
                        },
                        onDelete: {
                            viewModel.deleteTask(task)
                        },
                        viewModel: viewModel  // Add this line
                    )
                }
            }
        }
    }
}

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No tasks yet")
                .font(.headline)
            Text("Add tasks to start earning screen time!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct TaskRowView: View {
    let task: Task
    let onComplete: () -> Void
    let onDelete: () -> Void
    @StateObject var viewModel: TaskManagerViewModel
    @State private var showingDetails = false
    @State private var showingCelebration = false
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: task.category.icon)
                    .foregroundColor(task.category.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    
                    if let dueDate = task.dueDate {
                        Text("Due: \(dueDate, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !task.isCompleted {
                    Button(action: {
                        onComplete()
                        showingCelebration = true
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            if showingDetails {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Label("\(Int(task.duration/60))m", systemImage: "clock")
                        Label("\(task.points) pts", systemImage: "star.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            
            Button(action: { showingDetails.toggle() }) {
                HStack {
                    Text(showingDetails ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .opacity(task.isCompleted ? 0.6 : 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingCelebration) {
            TaskCompletionCelebrationView(
                task: task,
                viewModel: viewModel,
                showShareSheet: $showShareSheet
            )
        }
        .onChange(of: showShareSheet) { newValue in
            if newValue {
                viewModel.shareAchievement(task)
                showingCelebration = false
            }
        }
    }
}

// MARK: - New Task View
struct NewTaskView: View {
    @ObservedObject var viewModel: TaskManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = TaskCategory.custom
    @State private var duration: Double = 30 // minutes
    @State private var points = 10
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Duration & Points") {
                    VStack(alignment: .leading) {
                        Text("Duration: \(Int(duration)) minutes")
                            .font(.subheadline)
                        Slider(value: $duration, in: 5...180, step: 5)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Points: \(points)")
                            .font(.subheadline)
                        Slider(value: .init(
                            get: { Double(points) },
                            set: { points = Int($0) }
                        ), in: 5...50, step: 5)
                    }
                }
                
                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                Section {
                    Button(action: saveTask) {
                        Text("Add Task")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            points: points,
            dueDate: hasDueDate ? dueDate : nil
        )
        viewModel.addTask(newTask)
        dismiss()
    }
}

// MARK: - Preview Provider
struct TasksManagerView_Previews: PreviewProvider {
    static var previews: some View {
        TasksManagerView()
    }
}
