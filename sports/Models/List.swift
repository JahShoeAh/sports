//
//  List.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct GameList: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let userId: String
    let isPublic: Bool
    let isStaffList: Bool
    let gameIds: [String]
    let createdAt: Date
    let updatedAt: Date
    
    // User reference (populated when needed)
    let user: User?
    
    // Games reference (populated when needed)
    let games: [Game]?
    
    init(title: String, description: String? = nil, userId: String, isPublic: Bool = true, isStaffList: Bool = false, gameIds: [String] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.userId = userId
        self.isPublic = isPublic
        self.isStaffList = isStaffList
        self.gameIds = gameIds
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
        self.games = nil
    }
}

struct Watchlist: Identifiable, Codable {
    let id: String
    let userId: String
    var gameIds: [String]
    let createdAt: Date
    let updatedAt: Date
    
    init(userId: String, gameIds: [String] = []) {
        self.id = UUID().uuidString
        self.userId = userId
        self.gameIds = gameIds
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
