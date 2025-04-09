import SwiftUI
import FirebaseAuth

struct Follow: View {
    @State private var friendId: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter user to follow", text: $friendId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding()
            
            Button(action: {
                // Check if the user is authenticated
                if let userId = Auth.auth().currentUser?.uid {
                    print("Current user ID: \(userId)")
                    print("Friend ID: \(friendId)")
                    addFriend(userId: userId, friendId: friendId)
                } else {
                    print("User not authenticated")
                    // You can also trigger a sign-in process here if needed
                }
            }) {
                Text("Add Friend")
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .onAppear {
            // Ensure the user is authenticated on view appearance
            if let userId = Auth.auth().currentUser?.uid {
                print("Authenticated as: \(userId)")
            } else {
                print("No user authenticated")
            }
        }
    }
}

func addFriend(userId: String, friendId: String) {
    guard let url = URL(string: "https://social-media-api-73bqxnmzma-uc.a.run.app/api/friends/add") else {
        print("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let json: [String: Any] = [
        "userId": userId,
        "friendId": friendId
    ]

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])
    } catch {
        print("Failed to serialize JSON: \(error)")
        return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }

        guard let data = data else {
            print("No data received")
            return
        }

        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("Response: \(jsonResponse)")
            }
        } catch {
            print("Failed to decode JSON response: \(error)")
        }
    }

    task.resume()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Follow()
    }
}
