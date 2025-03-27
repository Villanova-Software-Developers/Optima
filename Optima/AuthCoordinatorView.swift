import SwiftUI
import FirebaseCore
import FirebaseAuth

class AuthStateManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    init() {
        // Check if user is already logged in from UserDefaults
        isAuthenticated = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }
}

struct AuthCoordinatorView: View {
    @StateObject private var authManager = AuthStateManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
            } else {
                NavigationStack {
                    AuthenticationView()
                        .environmentObject(authManager) // Pass the authManager to child views
                }
            }
        }
        .environmentObject(authManager) // Make sure ContentView can access the authManager too
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthStateManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Optima")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 50)
            
            NavigationLink(destination: SignIn().environmentObject(authManager)) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            NavigationLink(destination: SignUp()) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}
//filler