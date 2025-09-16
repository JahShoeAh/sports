//
//  Game.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

struct Game: Identifiable, Codable {
    let id: String
    let homeTeam: Team
    let awayTeam: Team
    let league: League
    let season: String
    let week: Int?
    let gameDate: Date
    let gameTime: Date
    let venue: String
    let city: String
    let state: String
    let country: String
    let status: GameStatus
    let homeScore: Int?
    let awayScore: Int?
    let quarter: Int?
    let timeRemaining: String?
    let isLive: Bool
    let isCompleted: Bool
    
    // Game details
    let startingLineups: StartingLineups?
    let boxScore: BoxScore?
    let gameStats: GameStats?
    
    var displayTitle: String {
        return "\(awayTeam.name) vs. \(homeTeam.name)"
    }
    
    var leagueDisplayName: String {
        return league.name
    }
}

struct StartingLineups: Codable {
    let home: [Player]
    let away: [Player]
}

struct BoxScore: Codable {
    let home: TeamBoxScore
    let away: TeamBoxScore
}

struct TeamBoxScore: Codable {
    let team: Team
    let stats: [String: Any] // TODO:QUESTION - Define specific stat structure per sport
    
    enum CodingKeys: String, CodingKey {
        case team
        case stats
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        team = try container.decode(Team.self, forKey: .team)
        stats = [:] // TODO: Implement proper stat decoding
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(team, forKey: .team)
        // TODO: Implement proper stat encoding
    }
}

struct GameStats: Codable {
    let home: TeamGameStats
    let away: TeamGameStats
}

struct TeamGameStats: Codable {
    let team: Team
    let statLeaders: [StatLeader]
}

struct StatLeader: Codable {
    let category: String
    let player: Player
    let value: String
}

enum GameStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case live = "live"
    case completed = "completed"
    case postponed = "postponed"
    case cancelled = "cancelled"
}
