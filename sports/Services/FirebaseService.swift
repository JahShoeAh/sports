//
//  FirebaseService.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isEmailVerified = false
    @Published var needsEmailVerification = false
    @Published var pendingVerificationEmail: String?
    @Published var pendingUserData: (username: String, displayName: String)?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {
        // Listen for authentication state changes
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.isAuthenticated = true
                    self?.isEmailVerified = user.isEmailVerified
                    
                    if user.isEmailVerified {
                        self?.needsEmailVerification = false
                        self?.fetchUserData(userId: user.uid)
                    } else {
                        self?.needsEmailVerification = true
                        self?.currentUser = nil
                    }
                } else {
                    self?.isAuthenticated = false
                    self?.isEmailVerified = false
                    self?.needsEmailVerification = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, username: String, displayName: String) async throws {
        print("🔥 Firebase Auth: Creating user with email: \(email)")
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            print("🔥 Firebase Auth: User created successfully with UID: \(result.user.uid)")
            
            // Store user data for later use (after email verification)
            try await storePendingUserData(email: email, username: username, displayName: displayName)
            
            // Send Firebase native verification email
            try await sendVerificationEmail(email: email)
            
            // Store pending data for later use
            DispatchQueue.main.async {
                self.pendingVerificationEmail = email
                self.pendingUserData = (username: username, displayName: displayName)
                self.needsEmailVerification = true
            }
            
            print("🔥 Firebase Auth: Verification email sent successfully")
        } catch {
            print("🔥 Firebase Auth Error: \(error)")
            throw error
        }
    }
    
    func checkEmailVerificationStatus() async throws {
        print("🔥 Firebase Auth: Checking email verification status...")
        
        guard let user = auth.currentUser else {
            print("🔥 Firebase Auth: No current user found")
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        print("🔥 Firebase Auth: Current user email: \(user.email ?? "nil")")
        print("🔥 Firebase Auth: Email verified before reload: \(user.isEmailVerified)")
        
        // Reload user to get updated verification status
        try await user.reload()
        
        print("🔥 Firebase Auth: Email verified after reload: \(user.isEmailVerified)")
        
        if user.isEmailVerified {
            print("🔥 Firebase Auth: Email verified successfully!")
            
            // Get stored user data
            let storedData = try await getStoredPendingUserData(email: user.email ?? "")
            print("🔥 Firebase Auth: Stored user data: \(storedData?.username ?? "nil"), \(storedData?.displayName ?? "nil")")
            
            // Create user profile
            let userProfile = User(
                id: user.uid,
                email: user.email ?? "",
                username: storedData?.username ?? "",
                displayName: storedData?.displayName ?? ""
            )
            
            print("🔥 Firebase Auth: Creating user profile: \(userProfile.username)")
            try await saveUser(userProfile)
            
            // Clean up pending data
            try await cleanupPendingUserData(email: user.email ?? "")
            
            DispatchQueue.main.async {
                print("🔥 Firebase Auth: Updating UI state")
                self.currentUser = userProfile
                self.pendingVerificationEmail = nil
                self.pendingUserData = nil
                self.needsEmailVerification = false
            }
        } else {
            print("🔥 Firebase Auth: Email not verified yet")
            throw NSError(domain: "AuthError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Email not verified. Please check your email and click the verification link."])
        }
    }
    
    func resendVerificationEmail() async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Send Firebase native verification email
        try await user.sendEmailVerification()
        
        print("🔥 Firebase Auth: Verification email resent to: \(user.email ?? "")")
    }
    
    func signIn(email: String, password: String) async throws {
        _ = try await auth.signIn(withEmail: email, password: password)
        
        // Check if email is verified
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        if !user.isEmailVerified {
            print("🔥 Email not verified for \(email)")
            
            // Check if there's pending user data
            let hasPendingData = try await checkForPendingUserData(email: email)
            
            if hasPendingData {
                // Restore pending data
                let storedData = try await getStoredPendingUserData(email: email)
                DispatchQueue.main.async {
                    self.pendingVerificationEmail = email
                    self.pendingUserData = storedData
                    self.needsEmailVerification = true
                }
            } else {
                // No pending data, just need verification
                DispatchQueue.main.async {
                    self.needsEmailVerification = true
                }
            }
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Admin Bypass (for development)
    func adminLogin() {
        let adminUser = User(
            id: "admin-user-id",
            email: "admin@sports.com",
            username: "admin",
            displayName: "Admin User"
        )
        
        DispatchQueue.main.async {
            self.currentUser = adminUser
            self.isAuthenticated = true
            self.isEmailVerified = true
            self.needsEmailVerification = false
            self.pendingVerificationEmail = nil
            self.pendingUserData = nil
        }
    }
    
    // MARK: - User Management
    private func fetchUserData(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    DispatchQueue.main.async {
                        self?.currentUser = user
                    }
                } catch {
                    print("Error decoding user: \(error)")
                }
            }
        }
    }
    
    private func fetchUserData(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        if document.exists {
            return try document.data(as: User.self)
        }
        return nil
    }
    
    private func saveUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
    }
    
    func updateUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
        self.currentUser = user
    }
    
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Reviews
    func saveReview(_ review: Review) async throws {
        try db.collection("reviews").document(review.id).setData(from: review)
    }
    
    func fetchReviews(for gameId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("gameId", isEqualTo: gameId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Review.self)
        }
    }
    
    func fetchUserReviews(userId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Review.self)
        }
    }
    
    // MARK: - Lists
    func saveList(_ list: GameList) async throws {
        try db.collection("lists").document(list.id).setData(from: list)
    }
    
    func fetchUserLists(userId: String) async throws -> [GameList] {
        let snapshot = try await db.collection("lists")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: GameList.self)
        }
    }
    
    func fetchPublicLists() async throws -> [GameList] {
        let snapshot = try await db.collection("lists")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: GameList.self)
        }
    }
    
    // MARK: - Watchlist
    func saveWatchlist(_ watchlist: Watchlist) async throws {
        try db.collection("watchlists").document(watchlist.id).setData(from: watchlist)
    }
    
    func fetchWatchlist(userId: String) async throws -> Watchlist? {
        let snapshot = try await db.collection("watchlists")
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        return snapshot.documents.first.flatMap { document in
            try? document.data(as: Watchlist.self)
        }
    }
    
    func addToWatchlist(userId: String, gameId: String) async throws {
        if var watchlist = try await fetchWatchlist(userId: userId) {
            if !watchlist.gameIds.contains(gameId) {
                watchlist.gameIds.append(gameId)
                try await saveWatchlist(watchlist)
            }
        } else {
            let watchlist = Watchlist(userId: userId, gameIds: [gameId])
            try await saveWatchlist(watchlist)
        }
    }
    
    func removeFromWatchlist(userId: String, gameId: String) async throws {
        if var watchlist = try await fetchWatchlist(userId: userId) {
            watchlist.gameIds.removeAll { $0 == gameId }
            try await saveWatchlist(watchlist)
        }
    }
    
    // MARK: - Polls
    func savePoll(_ poll: Poll) async throws {
        try db.collection("polls").document(poll.id).setData(from: poll)
    }
    
    func fetchPolls(for gameId: String) async throws -> [Poll] {
        let snapshot = try await db.collection("polls")
            .whereField("gameId", isEqualTo: gameId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Poll.self)
        }
    }
    
    func savePollVote(_ vote: PollVote) async throws {
        try db.collection("pollVotes").document(vote.id).setData(from: vote)
    }
    
    func fetchPollVotes(pollId: String) async throws -> [PollVote] {
        let snapshot = try await db.collection("pollVotes")
            .whereField("pollId", isEqualTo: pollId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: PollVote.self)
        }
    }
    
    // MARK: - Pending User Data Helpers
    private func storePendingUserData(email: String, username: String, displayName: String) async throws {
        let pendingData: [String: Any] = [
            "email": email,
            "username": username,
            "displayName": displayName,
            "createdAt": Date()
        ]
        
        try await db.collection("pendingUsers").document(email).setData(pendingData)
        print("🔥 Stored pending user data for \(email)")
    }
    
    private func getStoredPendingUserData(email: String) async throws -> (username: String, displayName: String)? {
        let document = try await db.collection("pendingUsers").document(email).getDocument()
        
        guard document.exists,
              let data = document.data(),
              let username = data["username"] as? String,
              let displayName = data["displayName"] as? String else {
            return nil
        }
        
        return (username: username, displayName: displayName)
    }
    
    private func checkForPendingUserData(email: String) async throws -> Bool {
        let document = try await db.collection("pendingUsers").document(email).getDocument()
        return document.exists
    }
    
    private func cleanupPendingUserData(email: String) async throws {
        try await db.collection("pendingUsers").document(email).delete()
        print("🔥 Cleaned up pending user data for \(email)")
    }
    
    private func sendVerificationEmail(email: String) async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Send Firebase native verification email
        try await user.sendEmailVerification()
        
        print("🔥 Firebase verification email sent to: \(user.email ?? email)")
        print("🔥 User should click the verification link in their email")
    }
    
}
