import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

struct ContentView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var FullName: String = ""
    @State private var Age: String = ""
    @State private var errorMessage: String = ""
    @State private var signUpSuccessful: Bool = false

    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Optima!")
                .font(.title)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: password) { newValue in
                    let validation = validatePassword(newValue)
                    passwordErrors = validation.errors
                    validRequirements = validation.valid
                }
            TextField("Full Name", text: $FullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            TextField("Age", text: $Age)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            Button(action: {
                // Call the sign-up function here
                signUp()
            }) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            passwordRequirementsView
            

            
            
            
            if signUpSuccessful {
                Text("Sign up is successful")
                    .foregroundColor(.green)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
        
    }
    
    @State private var passwordErrors: [String] = []
    @State private var validRequirements: [String] = []
        
        func validatePassword(_ password: String) -> (isValid: Bool, errors: [String], valid: [String]) {
            var errors: [String] = []
            var validItems: [String] = []
            
            // Define the requirements and their predicates
            let requirements = [
                ("Uppercase letter", ".*[A-Z]+.*"),
                ("Number", ".*[0-9]+.*"),
                ("Special character", ".*[!&^%$#@()/]+.*"),
                ("Lowercase letter", ".*[a-z]+.*")
            ]
            
            // Check each requirement
            for (requirement, regex) in requirements {
                if NSPredicate(format:"SELF MATCHES %@", regex).evaluate(with: password) {
                    validItems.append(requirement)
                } else {
                    errors.append(requirement)
                }
            }
            
            // Check length requirement
            if password.count >= 8 {
                validItems.append("Minimum 8 characters")
            } else {
                errors.append("Minimum 8 characters")
            }
            
            // Check if all requirements are met
            let isValid = errors.isEmpty
            
            return (isValid, errors, validItems)
        }
        
        func signUp() {
            // Validate password
            let validation = validatePassword(password)
            
            if !validation.isValid {
                passwordErrors = validation.errors
                validRequirements = validation.valid
                errorMessage = "Please complete all password requirements"
                signUpSuccessful = false
                return
            }
            
            // Proceed with Firebase sign-up if password is valid
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    signUpSuccessful = false
                } else {
                    signUpSuccessful = true
                    errorMessage = ""
                    passwordErrors = []
                    validRequirements = []
                }
            }
        }
        
        // Add this to your body view where you want to display the requirements
        var passwordRequirementsView: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text("Password requirements:")
                    .font(.caption)
                    .padding(.bottom, 5)
                
                // Show valid requirements in green
                ForEach(validRequirements, id: \.self) { requirement in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(requirement)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // Show missing requirements in red
                ForEach(passwordErrors, id: \.self) { error in
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical)
        }
    
}

@main
struct OptimaApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
