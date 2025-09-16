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
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {
        // Listen for authentication state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.isAuthenticated = true
                    self?.fetchUserData(userId: user.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Authentication
    func signUp(email: String, password: String, username: String, displayName: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let user = User(
            id: result.user.uid,
            email: email,
            username: username,
            displayName: displayName
        )
        
        try await saveUser(user)
        self.currentUser = user
    }
    
    func signIn(email: String, password: String) async throws {
        _ = try await auth.signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
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
    
    private func saveUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
    }
    
    func updateUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user)
        self.currentUser = user
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
    func saveList(_ list: List) async throws {
        try db.collection("lists").document(list.id).setData(from: list)
    }
    
    func fetchUserLists(userId: String) async throws -> [List] {
        let snapshot = try await db.collection("lists")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: List.self)
        }
    }
    
    func fetchPublicLists() async throws -> [List] {
        let snapshot = try await db.collection("lists")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(50)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: List.self)
        }
    }
    
    // MARK: - Watchlist
    func saveWatchlist(_ watchlist: Watchlist) async throws {
        try db.collection("watchlists").document(watchlist.id).setData(from: watchlist)
    }
    
    func fetchWatchlist(userId: String) async throws -> Watchlist? {
        let snapshot = try await db.collection("watchlists")
            .whereField("userId", isEqualTo: userId)
            .limit(1)
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
}
