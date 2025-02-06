import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TasksManagerView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(0)
            
            
 
            SocialCompletionFeedView()
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
                .tag(1)
            
            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    ContentView()
}
