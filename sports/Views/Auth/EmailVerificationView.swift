//
//  EmailVerificationView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct EmailVerificationView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResendConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Email Icon
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Check Your Email")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("We've sent a verification link to your email address. Please check your inbox and click the verification link to activate your account.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Verification Actions
                VStack(spacing: 20) {
                    Button(action: {
                        Task {
                            await checkVerificationStatus()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("I've Verified My Email")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: {
                        Task {
                            await resendVerificationEmail()
                        }
                    }) {
                        Text("Resend Verification Email")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    if showResendConfirmation {
                        Text("Verification email sent!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // Back to Sign In and Sign Out Options
                VStack(spacing: 12) {
                    Button(action: {
                        do {
                            try firebaseService.signOut()
                        } catch {
                            print("Sign out error: \(error)")
                        }
                    }) {
                        Text("Back to Sign In")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        do {
                            try firebaseService.signOut()
                        } catch {
                            print("Sign out error: \(error)")
                        }
                    }) {
                        Text("Sign Out")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func checkVerificationStatus() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Check if email is verified
            try await firebaseService.checkEmailVerificationStatus()
            print("✅ Email verification successful!")
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func resendVerificationEmail() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.showResendConfirmation = false
        }
        
        do {
            try await firebaseService.resendVerificationEmail()
            await MainActor.run {
                self.showResendConfirmation = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to resend verification email: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

#Preview {
    EmailVerificationView()
}
