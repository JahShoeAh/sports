//
//  Review.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct Review: Identifiable, Codable {
    let id: String
    let userId: String
    let gameId: String
    let entertainmentRating: Int? // 1-10 scale, optional
    let reactionIcon: ReactionIcon
    let viewingMethod: ViewingMethod? // optional
    let note: String?
    let containsSpoilers: Bool
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    
    // User and game references (populated when needed)
    let user: User?
    let game: Game?
    
    init(userId: String, gameId: String, entertainmentRating: Int? = nil, reactionIcon: ReactionIcon = .heart, viewingMethod: ViewingMethod? = nil, note: String? = nil, containsSpoilers: Bool = false, tags: [String] = []) {
        self.id = UUID().uuidString
        self.userId = userId
        self.gameId = gameId
        self.entertainmentRating = entertainmentRating
        self.reactionIcon = reactionIcon
        self.viewingMethod = viewingMethod
        self.note = note
        self.containsSpoilers = containsSpoilers
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.user = nil
        self.game = nil
    }
}

enum ReactionIcon: String, Codable, CaseIterable {
    case heart = "heart"
    case fire = "fire"
    case thumbsUp = "thumbsUp"
    case star = "star"
    case trophy = "trophy"
    
    var systemImageName: String {
        switch self {
        case .heart: return "heart.fill"
        case .fire: return "flame.fill"
        case .thumbsUp: return "hand.thumbsup.fill"
        case .star: return "star.fill"
        case .trophy: return "trophy.fill"
        }
    }
}

enum ViewingMethod: String, Codable, CaseIterable {
    case attended = "attended"
    case liveOnTV = "liveOnTV"
    case replay = "replay"
    case justHighlights = "justHighlights"
    
    var displayName: String {
        switch self {
        case .attended: return "Attended in person"
        case .liveOnTV: return "Live on TV"
        case .replay: return "Replay"
        case .justHighlights: return "Just Highlights"
        }
    }
}
