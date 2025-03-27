import SwiftUI

struct GETUSER: View {
    var body: some View {
        VStack {
            Button(action: {
                getUser(userId: "0w0HjVHIQAMBsupgUrGJ5LPTNgL2")
            }) {
                Text("Get User")
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

func getUser(userId: String) {
    guard let url = URL(string: "https://social-media-api-73bqxnmzma-uc.a.run.app/api/users/0w0HjVHIQAMBsupgUrGJ5LPTNgL2") else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status Code: \(httpResponse.statusCode)")
        }

        guard let data = data else {
            print("No data received")
            return
        }

        if let rawResponse = String(data: data, encoding: .utf8) {
            print("Raw Response (First 500 chars): \(rawResponse.prefix(500))")
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

struct Get_User: PreviewProvider {
    static var previews: some View {
        GETUSER()
    }
}
