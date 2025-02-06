import SwiftUI
import FirebaseCore
import FirebaseAuth

// Authentication state manager
class AuthStateManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
            }
        }
    }
}

struct SignIn: View {
    // MARK: - Properties
    @StateObject private var authManager = AuthStateManager()
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
            .onChange(of: authManager.isAuthenticated) { newValue in
                if newValue {
                    // Successfully authenticated
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    private func signIn() {
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            
            if let error = error {
                alertMessage = handleAuthError(error)
                showingAlert = true
            } else {
                // Successfully signed in
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                if let user = result?.user {
                    print("Successfully signed in user: \(user.uid)")
                }
            }
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let authError = error as NSError
        switch authError.code {
        case AuthErrorCode.wrongPassword.rawValue:
            return "Invalid password. Please try again."
        case AuthErrorCode.invalidEmail.rawValue:
            return "Invalid email address. Please check your email."
        case AuthErrorCode.userNotFound.rawValue:
            return "Account not found. Please sign up."
        case AuthErrorCode.userDisabled.rawValue:
            return "Your account has been disabled. Please contact support."
        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please try again later."
        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your internet connection."
        default:
            return "An error occurred. Please try again."
        }
    }
}

// MARK: - Supporting Views
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

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Enter your email address to receive a password reset link.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                CustomTextField(
                    text: $email,
                    placeholder: "Email",
                    systemImage: "envelope"
                )
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                
                Button(action: resetPassword) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                }
                .frame(height: 50)
                .padding(.horizontal)
                .disabled(email.isEmpty || isLoading)
                
                Spacer()
            }
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .alert("Password Reset", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    if alertMessage.contains("sent") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func resetPassword() {
        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
            } else {
                alertMessage = "Password reset link has been sent to your email."
            }
            showingAlert = true
        }
    }
}

#Preview {
    SignIn()
}
