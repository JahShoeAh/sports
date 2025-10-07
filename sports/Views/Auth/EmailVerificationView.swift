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
    @State private var resendCooldown = 0
    @State private var cooldownTimer: Timer?
    
    private let cooldownDuration = 30
    
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
                        print("Clicked: Send Verification Email. From page: Email Verification. Actions performed: resendVerificationEmail(). TODO: Send verification email with cooldown")
                        Task {
                            await resendVerificationEmail()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(resendCooldown > 0
                                 ? "Send Verification (\(resendCooldown)s)"
                                 : "Send Verification Email")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || resendCooldown > 0)
                    
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
                        print("Clicked: Back to Sign In. From page: Email Verification. Actions performed: firebaseService.signOut(). TODO: Sign out and return to authentication")
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
                }
            }
            .padding()
            .navigationBarHidden(true)
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
                startCooldown()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to resend verification email: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func startCooldown() {
        cooldownTimer?.invalidate()
        resendCooldown = cooldownDuration
        
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.resendCooldown > 0 {
                self.resendCooldown -= 1
            } else {
                timer.invalidate()
                self.cooldownTimer = nil
            }
        }
    }
}

#Preview {
    EmailVerificationView()
}
