import SwiftUI

struct SignIn: View {
    // MARK: - Properties
    @EnvironmentObject var authManager: AuthStateManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingForgotPassword: Bool = false
    @State private var showingSignUp: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Validation Properties
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") && email.contains(".")
    }
    
    // MARK: - Main View
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo or App Name
                        Text("Optima")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.top, 50)
                        
                        Text("Welcome Back!")
                            .font(.title2)
                            .fontWeight(.medium)
                            .padding(.bottom, 30)
                        
                        // Sign In Form
                        VStack(spacing: 25) {
                            // Email Field
                            CustomTextField(
                                text: $email,
                                placeholder: "Email",
                                systemImage: "envelope"
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            
                            // Password Field
                            CustomSecureField(
                                text: $password,
                                placeholder: "Password",
                                systemImage: "lock"
                            )
                            
                            // Forgot Password Button
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showingForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 5)
                            
                            // Sign In Button
                            Button(action: signIn) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                    
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign In")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(height: 50)
                            .disabled(!isFormValid || isLoading)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            
                            // Sign Up Option
                            HStack {
                                Text("Don't have an account?")
                                    .foregroundColor(.secondary)
                                Button("Sign Up") {
                                    showingSignUp = true
                                }
                                .foregroundColor(.blue)
                            }
                            .font(.subheadline)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
           }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .navigationDestination(isPresented: $showingSignUp) {
                SignUp()
            }
        }
    }
    
    // MARK: - Authentication Methods
    private func signIn() {
        isLoading = true
        
        // Prepare login request
        let loginData = [
            "email": email,
            "password": password
        ]
        
        guard let url = URL(string: "https://social-media-api-73bqxnmzma-uc.a.run.app/api/auth/login") else {
            handleError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
        } catch {
            handleError("Error preparing request")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    handleError(error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    handleError("No response from server")
                    return
                }
                
                guard let data = data else {
                    handleError("No data received")
                    return
                }
                
                switch httpResponse.statusCode {
                case 200:
                    // Parse the response to get the user ID
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            var userId = "user-\(Date().timeIntervalSince1970)"
                            var username = "User"
                            
                            // Try to extract user ID from different possible response formats
                            if let user = json["user"] as? [String: Any] {
                                userId = user["id"] as? String ?? userId
                                username = user["username"] as? String ?? username
                            } else if let userData = json["data"] as? [String: Any] {
                                userId = userData["userId"] as? String ?? userId
                                username = userData["username"] as? String ?? username
                            } else if let extractedUserId = json["userId"] as? String {
                                userId = extractedUserId
                            }
                            
                            // Store user information in UserDefaults
                            UserDefaults.standard.set(userId, forKey: "userId")
                            UserDefaults.standard.set(username, forKey: "username")
                            UserDefaults.standard.set(email, forKey: "userEmail")
                            
                            // print("User ID saved: \(userId)")
                            // print("Username saved: \(username)")
                            // print("Email saved: \(email)")
                            
                            // Create a complete user profile JSON
                            //filler
                            let userProfileData: [String: Any] = [
                                "id": userId,
                                "username": username,
                                "email": email,
                                "totalPoints": 0,
                                "currentStreak": 0,
                                "joinDate": Date().timeIntervalSince1970,
                                "achievements": [],
                                "preferences": [
                                    "isDarkMode": false,
                                    "notificationsEnabled": true,
                                    "dailyScreenTimeLimit": 4 * 3600,
                                    "isProfilePublic": true
                                ]
                            ]
                            
                            // Try to save the complete user profile
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: userProfileData)
                                UserDefaults.standard.set(jsonData, forKey: "userProfile")
                            } catch {
                                print("Error saving user profile: \(error.localizedDescription)")
                            }
                        }
                    } catch {
                        print("Error parsing response: \(error.localizedDescription)")
                        // Still save a fallback ID
                        UserDefaults.standard.set("user-\(Date().timeIntervalSince1970)", forKey: "userId")
                    }
                    
                    // Set authentication state
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    self.authManager.isAuthenticated = true
                    print("Authentication successful, authManager.isAuthenticated = \(self.authManager.isAuthenticated)")
                    
                case 401:
                    handleError("Invalid email or password")
                case 500:
                    handleError("Server error. Please try again later.")
                default:
                    handleError("Account not registered. Please sign up")
                }
            }
        }.resume()
    }
    
    private func handleError(_ message: String) {
        alertMessage = message
        showingAlert = true
        isLoading = false
    }
}

// MARK: - Supporting Views (CustomTextField and CustomSecureField remain the same as in the original code)
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 20)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}


struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    @State private var isSecured: Bool = true
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecured {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Forgot Password View (Temporarily removed as it's tied to Firebase)
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Forgot Password functionality is currently unavailable.")
    }
}

#Preview {
    SignIn()
}
