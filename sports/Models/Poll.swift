//
//  Poll.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct Poll: Identifiable, Codable {
    let id: String
    let gameId: String
    let question: String
    let options: [PollOption]
    let isActive: Bool
    let gameStartTime: Date
    let createdAt: Date
    let updatedAt: Date
    
    init(gameId: String, question: String, options: [PollOption], gameStartTime: Date) {
        self.id = UUID().uuidString
        self.gameId = gameId
        self.question = question
        self.options = options
        self.isActive = true
        self.gameStartTime = gameStartTime
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct PollOption: Identifiable, Codable {
    let id: String
    let text: String
    let teamId: String?
    let voteCount: Int
    
    init(text: String, teamId: String? = nil, voteCount: Int = 0) {
        self.id = UUID().uuidString
        self.text = text
        self.teamId = teamId
        self.voteCount = voteCount
    }
}

struct PollVote: Identifiable, Codable {
    let id: String
    let pollId: String
    let userId: String
    let optionId: String
    let createdAt: Date
    
    init(pollId: String, userId: String, optionId: String) {
        self.id = UUID().uuidString
        self.pollId = pollId
        self.userId = userId
        self.optionId = optionId
        self.createdAt = Date()
    }
}
