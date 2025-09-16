//
//  User.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let username: String
    let displayName: String
    let bio: String?
    let avatarURL: String?
    let followers: [String] // User IDs
    let following: [String] // User IDs
    let createdAt: Date
    let updatedAt: Date
    
    // User statistics
    let gamesWatched: Int
    let reviewsCount: Int
    let listsCount: Int
    let watchlistCount: Int
    
    init(id: String, email: String, username: String, displayName: String, bio: String? = nil, avatarURL: String? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.avatarURL = avatarURL
        self.followers = []
        self.following = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.gamesWatched = 0
        self.reviewsCount = 0
        self.listsCount = 0
        self.watchlistCount = 0
    }
}
