import SwiftUI

struct SocialCompletionFeedView: View {
    // Sample feed data
    let completions = [
        GoalCompletion(
            userId: "1",
            username: "Sarah",
            goalTitle: "Morning Meditation",
            description: "Started my day with a clear mind 🧘‍♀️ 30 days streak!",
            duration: 20,
            points: 25,
            completedAt: Date(),
            goalType: .meditation,
            likes: 12,
            comments: [
                GoalComment(
                    userId: "2",
                    username: "Mike",
                    content: "This inspired me to start meditation too!",
                    timestamp: Date().addingTimeInterval(-300)
                )
            ]
        ),
        GoalCompletion(
            userId: "2",
            username: "Alex",
            goalTitle: "Coding Session",
            description: "Completed the SwiftUI module! Ready for the next challenge 💻",
            duration: 45,
            points: 30,
            completedAt: Date().addingTimeInterval(-1800),
            goalType: .study,
            likes: 8,
            comments: [
                GoalComment(
                    userId: "3",
                    username: "Emma",
                    content: "What are you learning next?",
                    timestamp: Date().addingTimeInterval(-900)
                )
            ]
        ),
        GoalCompletion(
            userId: "3",
            username: "John",
            goalTitle: "HIIT Workout",
            description: "New personal best! 🏃‍♂️ Those burpees were tough!",
            duration: 30,
            points: 40,
            completedAt: Date().addingTimeInterval(-3600),
            goalType: .workout,
            likes: 15,
            comments: [
                GoalComment(
                    userId: "4",
                    username: "Lisa",
                    content: "Beast mode! 💪",
                    timestamp: Date().addingTimeInterval(-1800)
                ),
                GoalComment(
                    userId: "5",
                    username: "David",
                    content: "What's your workout routine?",
                    timestamp: Date().addingTimeInterval(-1200)
                )
            ]
        ),
        GoalCompletion(
            userId: "4",
            username: "Emma",
            goalTitle: "Deep Focus Session",
            description: "2 hours of uninterrupted work! Project milestone achieved ✨",
            duration: 120,
            points: 50,
            completedAt: Date().addingTimeInterval(-7200),
            goalType: .focus,
            likes: 20,
            comments: [
                GoalComment(
                    userId: "1",
                    username: "Sarah",
                    content: "That's amazing focus! Any tips?",
                    timestamp: Date().addingTimeInterval(-3600)
                )
            ]
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(completions) { completion in
                        CompletionCard(completion: completion)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGray6))
            .navigationTitle("Achievement Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add new achievement action
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title2)
                    }
                }
            }
        }
    }
}

// Preview provider
struct SocialCompletionFeedView_Previews: PreviewProvider {
    static var previews: some View {
        SocialCompletionFeedView()
    }
}
