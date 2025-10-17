//
//  EditProfileView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseService = FirebaseService.shared
    
    // Profile data
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    // Validation states
    @State private var nameError: String?
    @State private var usernameError: String?
    @State private var bioError: String?
    @State private var isUsernameTaken = false
    @State private var isCheckingUsername = false
    
    // UI states
    @State private var isLoading = false
    @State private var showImagePicker = false
    
    // Character limits
    private let nameLimit = 20
    private let usernameLimit = 20
    private let bioLimit = 200
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Photo Section
                    VStack(spacing: 16) {
                        Text("Profile Photo")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            print("Clicked: Change Profile Photo. From page: Edit Profile. Actions performed: showImagePicker = true. TODO: Show photo picker")
                            showImagePicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 120, height: 120)
                                
                                if let profileImage = profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                }
                                
                                // Camera overlay
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "camera.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                    }
                                }
                                .frame(width: 120, height: 120)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Display Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter your display name", text: $displayName)
                            .textFieldStyle(EditProfileTextFieldStyle(
                                isValid: nameError == nil,
                                hasError: nameError != nil
                            ))
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
                    
                    // Username Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text("@")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            TextField("username", text: $username)
                                .textFieldStyle(EditProfileTextFieldStyle(
                                    isValid: usernameError == nil && !isUsernameTaken,
                                    hasError: usernameError != nil || isUsernameTaken
                                ))
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
                    
                    // Bio Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(bioError != nil ? Color.red : Color.clear, lineWidth: 2)
                            )
                            .onChange(of: bio) { _, newValue in
                                validateBio(newValue)
                            }
                        
                        HStack {
                            Text("\(bio.count)/\(bioLimit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let bioError = bioError {
                                Text(bioError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("Clicked: Cancel. From page: Edit Profile. Actions performed: dismiss(). TODO: Close edit profile without saving")
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("Clicked: Save. From page: Edit Profile. Actions performed: saveProfile(). TODO: Save profile changes to database")
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhoto)
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let newValue = newValue {
                        await loadImage(from: newValue)
                    }
                }
            }
        }
    }
    
    // MARK: - Validation Methods
    
    private func validateName(_ newValue: String) {
        // Check character limit
        if newValue.count > nameLimit {
            nameError = "Name cannot exceed \(nameLimit) characters"
            flashTextField()
            return
        }
        
        // Check for emojis
        if containsEmoji(newValue) {
            nameError = "Name cannot contain emojis"
            flashTextField()
            return
        }
        
        nameError = nil
    }
    
    private func validateUsername(_ newValue: String) {
        // Check character limit
        if newValue.count > usernameLimit {
            usernameError = "Username cannot exceed \(usernameLimit) characters"
            flashTextField()
            return
        }
        
        // Check for valid characters (only lowercase letters, numbers, "." and "_")
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._")
        let usernameCharacterSet = CharacterSet(charactersIn: newValue)
        
        if !allowedCharacters.isSuperset(of: usernameCharacterSet) {
            usernameError = "Username can only contain lowercase letters, numbers, '.' and '_'"
            flashTextField()
            return
        }
        
        usernameError = nil
        
        // Check username availability (debounced)
        if !newValue.isEmpty && newValue != firebaseService.currentUser?.username {
            checkUsernameAvailability(newValue)
        } else {
            isUsernameTaken = false
        }
    }
    
    private func validateBio(_ newValue: String) {
        // Check character limit
        if newValue.count > bioLimit {
            bioError = "Bio cannot exceed \(bioLimit) characters"
            flashTextField()
            return
        }
        
        bioError = nil
    }
    
    private func containsEmoji(_ text: String) -> Bool {
        return text.unicodeScalars.contains { scalar in
            return scalar.properties.isEmoji
        }
    }
    
    private func flashTextField() {
        // This would trigger a visual flash effect
        // For now, we'll rely on the red border from the error state
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
    
    private var isFormValid: Bool {
        return nameError == nil && 
               usernameError == nil && 
               bioError == nil && 
               !isUsernameTaken &&
               !displayName.isEmpty &&
               !username.isEmpty
    }
    
    private func loadCurrentProfile() {
        print("🔍 Loading current profile...")
        print("🔍 Current user: \(firebaseService.currentUser?.displayName ?? "nil")")
        
        if let user = firebaseService.currentUser {
            displayName = user.displayName
            username = user.username
            bio = user.bio ?? ""
            print("✅ Profile loaded: \(displayName), @\(username)")
        } else {
            print("❌ No current user found - this might be due to Firestore not being enabled")
            // Set some default values for testing
            displayName = "User"
            username = "username"
            bio = ""
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        
        await MainActor.run {
            self.profileImage = image
        }
    }
    
    private func saveProfile() async {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            // Update user profile - preserve all existing data
            guard let currentUser = firebaseService.currentUser else { return }
            
            let updatedUser = User(
                id: userId,
                email: currentUser.email,
                username: username,
                displayName: displayName,
                bio: bio.isEmpty ? nil : bio,
                avatarURL: currentUser.avatarURL
            )
            
            try await firebaseService.updateUser(updatedUser)
            
            await MainActor.run {
                self.isLoading = false
                self.dismiss()
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                // TODO: Show error alert
                print("Error saving profile: \(error)")
            }
        }
    }
}

// MARK: - Custom Text Field Style

struct EditProfileTextFieldStyle: TextFieldStyle {
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
    EditProfileView()
}
