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
    @State private var showSignUpSuccess = false
    
    // Validation states
    @State private var nameError: String?
    @State private var usernameError: String?
    @State private var isUsernameTaken = false
    @State private var isCheckingUsername = false
    
    // Character limits
    private let nameLimit = 20
    private let usernameLimit = 20
    
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
                        // Display Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Display Name", text: $displayName)
                                .textFieldStyle(AuthTextFieldStyle(
                                    isValid: nameError == nil,
                                    hasError: nameError != nil
                                ))
                                .autocapitalization(.words)
                                .onChange(of: displayName) { _, newValue in
                                    validateName(newValue)
                                }
                            
                            HStack {
                                Text("\(displayName.count)/\(nameLimit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if let nameError = nameError {
                                    Text(nameError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("@")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                TextField("username", text: $username)
                                    .textFieldStyle(AuthTextFieldStyle(
                                        isValid: usernameError == nil && !isUsernameTaken,
                                        hasError: usernameError != nil || isUsernameTaken
                                    ))
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .onChange(of: username) { _, newValue in
                                        validateUsername(newValue)
                                    }
                            }
                            
                            HStack {
                                Text("\(username.count)/\(usernameLimit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if isCheckingUsername {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                
                                if let usernameError = usernameError {
                                    Text(usernameError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else if isUsernameTaken {
                                    Text("This username is already taken")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
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
                    
                    if showSignUpSuccess {
                        Text("Account created! Please check your email for verification.")
                            .font(.caption)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        print("Clicked: \(isSignUp ? "Sign Up" : "Sign In"). From page: Authentication. Actions performed: handleAuthentication(). TODO: Authenticate user")
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
                    .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && (!isFormValid || username.isEmpty || displayName.isEmpty)))
                }
                
                // Toggle Sign Up/Sign In
                Button(action: {
                    print("Clicked: \(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up"). From page: Authentication. Actions performed: isSignUp.toggle(), errorMessage = nil. TODO: Toggle between sign up and sign in")
                    isSignUp.toggle()
                    errorMessage = nil
                    clearValidationErrors()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                // Admin Login Button (for development)
                Button(action: {
                    print("Clicked: Admin Login (Dev). From page: Authentication. Actions performed: firebaseService.adminLogin(). TODO: Bypass authentication for development")
                    firebaseService.adminLogin()
                }) {
                    Text("Admin Login (Dev)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .padding(.top, 8)
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
                print("🔐 Attempting to sign up user: \(email)")
                try await firebaseService.signUp(
                    email: email,
                    password: password,
                    username: username,
                    displayName: displayName
                )
                print("✅ Sign up successful!")
                await MainActor.run {
                    self.showSignUpSuccess = true
                    self.isLoading = false
                }
            } else {
                print("🔐 Attempting to sign in user: \(email)")
                try await firebaseService.signIn(email: email, password: password)
                print("✅ Sign in successful!")
            }
        } catch {
            print("❌ Authentication error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateName(_ newValue: String) {
        // Check character limit
        if newValue.count > nameLimit {
            nameError = "Name cannot exceed \(nameLimit) characters"
            return
        }
        
        // Check for emojis
        if containsEmoji(newValue) {
            nameError = "Name cannot contain emojis"
            return
        }
        
        nameError = nil
    }
    
    private func validateUsername(_ newValue: String) {
        // Check character limit
        if newValue.count > usernameLimit {
            usernameError = "Username cannot exceed \(usernameLimit) characters"
            return
        }
        
        // Check for valid characters (only lowercase letters, numbers, "." and "_")
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._")
        let usernameCharacterSet = CharacterSet(charactersIn: newValue)
        
        if !allowedCharacters.isSuperset(of: usernameCharacterSet) {
            usernameError = "Username can only contain lowercase letters, numbers, '.' and '_'"
            return
        }
        
        usernameError = nil
        
        // Check username availability (debounced)
        if !newValue.isEmpty {
            checkUsernameAvailability(newValue)
        } else {
            isUsernameTaken = false
        }
    }
    
    private func containsEmoji(_ text: String) -> Bool {
        return text.unicodeScalars.contains { scalar in
            return scalar.properties.isEmoji
        }
    }
    
    // MARK: - Username Availability Check
    
    private func checkUsernameAvailability(_ username: String) {
        isCheckingUsername = true
        isUsernameTaken = false
        
        // Debounce the check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                do {
                    let isTaken = try await firebaseService.checkUsernameAvailability(username)
                    await MainActor.run {
                        self.isUsernameTaken = isTaken
                        self.isCheckingUsername = false
                    }
                } catch {
                    await MainActor.run {
                        self.isUsernameTaken = false
                        self.isCheckingUsername = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func clearValidationErrors() {
        nameError = nil
        usernameError = nil
        isUsernameTaken = false
        isCheckingUsername = false
    }
    
    // MARK: - Helper Properties
    
    private var isFormValid: Bool {
        return nameError == nil && 
               usernameError == nil && 
               !isUsernameTaken
    }
}

// MARK: - Custom Text Field Style

struct AuthTextFieldStyle: TextFieldStyle {
    let isValid: Bool
    let hasError: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(hasError ? Color.red : (isValid ? Color.clear : Color.clear), lineWidth: 2)
            )
    }
}

#Preview {
    AuthenticationView()
}
