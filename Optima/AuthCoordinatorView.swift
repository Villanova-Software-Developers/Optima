//
//  AuthCoordinatorView.swift
//  Optima
//
//  Created by Swopnil  Panday on 2/5/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

struct AuthCoordinatorView: View {
    @StateObject private var authManager = AuthStateManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
            } else {
                NavigationStack {  // Changed from NavigationView
                    AuthenticationView()
                }
            }
        }
    }
}

struct AuthenticationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Optima")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 50)
            
            NavigationLink(destination: SignIn()) {
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
