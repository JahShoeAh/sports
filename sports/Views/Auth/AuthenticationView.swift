//
//  AuthenticationView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("SportsLog")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Log your sports experiences")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Form
                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                        
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        Task {
                            await handleAuthentication()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && (username.isEmpty || displayName.isEmpty)))
                }
                
                // Toggle Sign Up/Sign In
                Button(action: {
                    isSignUp.toggle()
                    errorMessage = nil
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func handleAuthentication() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                try await firebaseService.signUp(
                    email: email,
                    password: password,
                    username: username,
                    displayName: displayName
                )
            } else {
                try await firebaseService.signIn(email: email, password: password)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
