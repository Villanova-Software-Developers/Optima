import SwiftUI
import Foundation

struct SignUp: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var age: String = ""
    @State private var errorMessage: String = ""
    @State private var signUpSuccessful: Bool = false
    @State private var passwordErrors: [String] = []
    @State private var validRequirements: [String] = []

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
                .onChange(of: password) { newValue in
                    let validation = validatePassword(newValue)
                    passwordErrors = validation.errors
                    validRequirements = validation.valid
                }

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
                .autocapitalization(.none)
            
            TextField("Age", text: $age)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .keyboardType(.numberPad)

            Button(action: {
                registerUser(email: email, password: password, username: username, age: age)
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
                Text("Sign up is successful!")
                    .foregroundColor(.green)
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    func registerUser(email: String, password: String, username: String, age: String) {
        let validation = validatePassword(password)
        
        if !validation.isValid {
            passwordErrors = validation.errors
            validRequirements = validation.valid
            errorMessage = "Please complete all password requirements"
            signUpSuccessful = false
            return
        }
        
        // Check if the age is a valid number
        guard let ageInt = Int(age), ageInt > 0 else {
            errorMessage = "Please enter a valid age"
            signUpSuccessful = false
            return
        }

        guard let url = URL(string: "https://social-media-api-73bqxnmzma-uc.a.run.app/api/auth/register") else {
            errorMessage = "Invalid URL"
            signUpSuccessful = false
            return
        }

        let parameters: [String: Any] = [
            "email": email,
            "password": password,
            "username": username,
            "age": ageInt  // Convert to integer as the API might expect a number not a string
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            errorMessage = "Error encoding parameters"
            signUpSuccessful = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Request error: \(error.localizedDescription)"
                    signUpSuccessful = false
                }
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    errorMessage = "Invalid response"
                    signUpSuccessful = false
                }
                return
            }

            // Print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }

            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                do {
                    // First try with the detailed response structure
                    let responseObject = try JSONDecoder().decode(UserRegistrationResponse.self, from: data)
                    DispatchQueue.main.async {
                        signUpSuccessful = true
                        errorMessage = ""
                        dismiss()
                    }
                } catch {
                    do {
                        // Fallback to a simpler response structure
                        let simpleResponse = try JSONDecoder().decode(SimpleResponse.self, from: data)
                        DispatchQueue.main.async {
                            if simpleResponse.success {
                                signUpSuccessful = true
                                errorMessage = ""
                                dismiss()
                            } else {
                                signUpSuccessful = false
                                errorMessage = simpleResponse.message ?? "Unknown error"
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            print("Decoding error: \(error)")
                            errorMessage = "Error decoding response: \(error.localizedDescription)"
                            signUpSuccessful = false
                        }
                    }
                }
            } else {
                do {
                    // Try to decode error message
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        errorMessage = errorResponse.message ?? "HTTP Error: \(httpResponse.statusCode)"
                        signUpSuccessful = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        errorMessage = "HTTP Error: \(httpResponse.statusCode)"
                        signUpSuccessful = false
                    }
                }
            }
        }.resume()
    }

    func validatePassword(_ password: String) -> (isValid: Bool, errors: [String], valid: [String]) {
        var errors: [String] = []
        var validItems: [String] = []

        let requirements = [
            ("Uppercase letter", ".*[A-Z]+.*"),
            ("Number", ".*[0-9]+.*"),
            ("Special character", ".*[!&^%$#@()/]+.*"),
            ("Lowercase letter", ".*[a-z]+.*")
        ]

        for (requirement, regex) in requirements {
            if NSPredicate(format:"SELF MATCHES %@", regex).evaluate(with: password) {
                validItems.append(requirement)
            } else {
                errors.append(requirement)
            }
        }
//filler
        if password.count >= 8 {
            validItems.append("Minimum 8 characters")
        } else {
            errors.append("Minimum 8 characters")
        }

        let isValid = errors.isEmpty
        return (isValid, errors, validItems)
    }

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

// Multiple response structures to handle potential API response formats

struct UserRegistrationResponse: Codable {
    let success: Bool
    let user: User?
    let error: String?
}

struct User: Codable {
    let email: String
    let username: String
    // You can add more fields here as needed
}

// Simple response format
struct SimpleResponse: Codable {
    let success: Bool
    let message: String?
}

// Error response format
struct ErrorResponse: Codable {
    let success: Bool?
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
    }
}
