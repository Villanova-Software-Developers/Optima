import SwiftUI
import FirebaseAuth
// In your goal completion view or wherever you track goal completion
struct GoalView: View {
    @State private var showCompletionCard = false
    @State private var completedGoal: GoalCompletion?
    
    var body: some View {
        VStack {
            // Your existing goal tracking UI here
            
            // Example button to complete goal
            Button("Complete Goal") {
                handleGoalCompletion()
            }
        }
        .sheet(isPresented: $showCompletionCard) {
            if let goal = completedGoal {
                CompletionCard(completion: goal)
            }
        }
    }
    
    private func handleGoalCompletion() {
        // Create the completed goal
        let completion = GoalCompletion(
            userId: "currentUserId", // Get from your auth system
            username: "Current User", // Get from your auth system
            goalTitle: "Morning Workout",
            description: "Completed my daily workout! 💪",
            duration: 30,
            points: 15,
            completedAt: Date(),
            goalType: .workout,
            likes: 0,
            comments: []
        )
        
        // Set the completed goal and show the card
        completedGoal = completion
        showCompletionCard = true
    }
}

// If you want to show it in your feed
struct FeedView: View {
    @State private var completedGoals: [GoalCompletion] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(completedGoals) { goal in
                    CompletionCard(completion: goal)
                }
            }
            .padding()
        }
        .onAppear {
            loadCompletedGoals()
        }
    }
    
    private func loadCompletedGoals() {
        // Load your completed goals here
        // This is example data
        completedGoals = [
            GoalCompletion(
                userId: "1",
                username: "John",
                goalTitle: "Morning Workout",
                description: "Great way to start the day! 💪",
                duration: 30,
                points: 15,
                completedAt: Date(),
                goalType: .workout,
                likes: 5,
                comments: []
            )
        ]
    }
}

// MARK: - Models
struct GoalComment: Identifiable {
    let id = UUID()
    let userId: String
    let username: String
    let content: String
    let timestamp: Date
}

struct GoalCompletion: Identifiable {
    let id = UUID()
    let userId: String
    let username: String
    let goalTitle: String
    let description: String
    let duration: Int // in minutes
    let points: Int
    let completedAt: Date
    let goalType: GoalType
    var likes: Int
    var comments: [GoalComment]
}

enum GoalType: String, CaseIterable {
    case workout = "Workout"
    case meditation = "Meditation"
    case study = "Study"
    case focus = "Focus Time"
    
    var icon: String {
        switch self {
        case .workout: return "figure.run"
        case .meditation: return "brain.head.profile"
        case .study: return "book.fill"
        case .focus: return "timer"
        }
    }
    
    var color: Color {
        switch self {
        case .workout: return .green
        case .meditation: return .purple
        case .study: return .blue
        case .focus: return .orange
        }
    }
    
    var backgroundPattern: String {
        switch self {
        case .workout: return "figure.walk"
        case .meditation: return "sunrise"
        case .study: return "books.vertical"
        case .focus: return "clock"
        }
    }
}

// MARK: - Views
struct CompletionCard: View {
    let completion: GoalCompletion
    @State private var showShareSheet = false
    @State private var additionalText = ""
    @State private var showingComments = false
    @State private var liked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Certificate Header
            HStack {
                Circle()
                    .fill(completion.goalType.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                    Image(systemName: completion.goalType.icon)
                        .foregroundColor(completion.goalType.color)
                        .font(.title3)
                )
                
                VStack(alignment: .leading) {
                    Text(completion.username)
                        .font(.headline)
                    Text(completion.completedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(completion.goalType.color)
                    .font(.title2)
            }
            
            // Achievement Details
            VStack(spacing: 12) {
                Text("🎉 Goal Completed!")
                    .font(.title3.bold())
                    .foregroundColor(completion.goalType.color)
                
                Text(completion.goalTitle)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("\(completion.duration)m")
                            .font(.subheadline)
                    }
                    
                    VStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(completion.points)pts")
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(completion.goalType.color.opacity(0.1))
            )
            
            // User's Comment
            if !completion.description.isEmpty {
                Text(completion.description)
                    .font(.body)
                    .padding(.vertical, 4)
            }
            
            // Social Interactions
            HStack(spacing: 20) {
                Button(action: { liked.toggle() }) {
                    HStack {
                        Image(systemName: liked ? "heart.fill" : "heart")
                            .foregroundColor(liked ? .red : .gray)
                        Text("\(completion.likes + (liked ? 1 : 0))")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: { showingComments.toggle() }) {
                    HStack {
                        Image(systemName: "bubble.left")
                        Text("\(completion.comments.count)")
                    }
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: { showShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(completion.goalType.color)
                }
            }
            
            if showingComments {
                CommentSection(comments: completion.comments)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(completion: completion, additionalText: $additionalText)
        }
    }
}

struct ShareSheet: View {
    let completion: GoalCompletion
    @Binding var additionalText: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Preview Card
                VStack {
                    CompletionBadge(completion: completion)
                        .frame(height: 200)
                        .padding()
                    
                    TextEditor(text: $additionalText)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3))
                        )
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Share Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") {
                        // Share functionality here
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CompletionBadge: View {
    let completion: GoalCompletion
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(completion.goalType.color)
            
            Text("Achievement Unlocked!")
                .font(.title3.bold())
            
            Text(completion.goalTitle)
                .font(.headline)
            
            HStack(spacing: 16) {
                Label("\(completion.duration)m", systemImage: "clock")
                Label("\(completion.points)pts", systemImage: "star.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            ZStack {
                completion.goalType.color.opacity(0.1)
                
                // Decorative Pattern
                GeometryReader { geo in
                    ForEach(0..<5) { row in
                        ForEach(0..<5) { col in
                            Image(systemName: completion.goalType.backgroundPattern)
                                .foregroundColor(completion.goalType.color.opacity(0.1))
                                .rotationEffect(.degrees(45))
                                .position(
                                    x: geo.size.width / 4 * CGFloat(col),
                                    y: geo.size.height / 4 * CGFloat(row)
                                )
                        }
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(completion.goalType.color.opacity(0.3), lineWidth: 2)
        )
    }
}

struct CommentSection: View {
    let comments: [GoalComment]
    @State private var newComment = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            
            ForEach(comments) { comment in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(comment.username)
                            .font(.subheadline.bold())
                        Text("·")
                        Text(comment.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(comment.content)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
            
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    // Add comment logic
                    newComment = ""
                }) {
                    Text("Post")
                        .foregroundColor(.blue)
                }
                .disabled(newComment.isEmpty)
            }
        }
    }
}


struct CompletionCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            CompletionCard(completion: GoalCompletion(
                userId: "1",
                username: "John",
                goalTitle: "Morning Workout",
                description: "Great way to start the day! 💪",
                duration: 30,
                points: 15,
                completedAt: Date(),
                goalType: .workout,
                likes: 5,
                comments: [
                    GoalComment(
                        userId: "2",
                        username: "Sarah",
                        content: "Way to go! 🎉",
                        timestamp: Date()
                    )
                ]
            ))
            .padding()
        }
        .background(Color(.systemGray6))
    }
}
