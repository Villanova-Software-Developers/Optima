import SwiftUI

struct SearchUser: View {
    @State private var userInput: String = ""
    @State private var responseText: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter username", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding()

            Button(action: {
                searchUser(username: userInput)
            }) {
                Text("Search User")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            ScrollView {
                VStack {
                    // Display each user in the responseText
                    ForEach(responseText.split(separator: ","), id: \.self) { username in
                        Text(username.trimmingCharacters(in: .whitespacesAndNewlines))
                            .padding()
                    }
                }
            }
        }
    }

    func searchUser(username: String) {
        guard let url = URL(string: "https://social-media-api-73bqxnmzma-uc.a.run.app/api/users/search/\(username)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            if let response = response as? HTTPURLResponse {
                print("HTTP Status Code: \(response.statusCode)")
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(UserResponse.self, from: data)
                DispatchQueue.main.async {
                    // Join usernames into a single string with commas, you can choose a different format if preferred
                    responseText = decodedResponse.users.map { $0.username }.joined(separator: ", ")
                }
            } catch {
                print("JSON Decoding Error: \(error)")
            }
        }

        task.resume()
    }
}

// Define a struct to match the API response
struct UserResponse: Codable {
    let success: Bool
    let users: [UserDetails]
}

struct UserDetails: Codable {
    let username: String
}

struct Search_User: PreviewProvider {
    static var previews: some View {
        SearchUser()
    }
}
