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
            
            Follow()
                .tabItem {
                    Label("Follow", systemImage: "person.fill")
                }
                .tag(3)
            GETUSER()
                .tabItem {
                    Label("Get User", systemImage: "person.fill")
                }
                .tag(4)
            SearchUser()
                .tabItem {
                    Label("Search User", systemImage: "person.fill")
                }
                .tag(5)
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    ContentView()
}
