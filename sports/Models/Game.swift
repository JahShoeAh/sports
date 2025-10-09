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
    
    // Default memberwise initializer
    init(id: String, homeTeam: Team, awayTeam: Team, league: League, season: String, week: Int?, gameDate: Date, gameTime: Date, venue: String, city: String, state: String, country: String, homeScore: Int?, awayScore: Int?, quarter: Int?, timeRemaining: String?, isLive: Bool, isCompleted: Bool, startingLineups: StartingLineups?, boxScore: BoxScore?, gameStats: GameStats?) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.league = league
        self.season = season
        self.week = week
        self.gameDate = gameDate
        self.gameTime = gameTime
        self.venue = venue
        self.city = city
        self.state = state
        self.country = country
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.quarter = quarter
        self.timeRemaining = timeRemaining
        self.isLive = isLive
        self.isCompleted = isCompleted
        self.startingLineups = startingLineups
        self.boxScore = boxScore
        self.gameStats = gameStats
    }
    
    // Custom date decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        homeTeam = try container.decode(Team.self, forKey: .homeTeam)
        awayTeam = try container.decode(Team.self, forKey: .awayTeam)
        league = try container.decode(League.self, forKey: .league)
        season = try container.decode(String.self, forKey: .season)
        week = try container.decodeIfPresent(Int.self, forKey: .week)
        venue = try container.decode(String.self, forKey: .venue)
        city = try container.decode(String.self, forKey: .city)
        state = try container.decode(String.self, forKey: .state)
        country = try container.decode(String.self, forKey: .country)
        homeScore = try container.decodeIfPresent(Int.self, forKey: .homeScore)
        awayScore = try container.decodeIfPresent(Int.self, forKey: .awayScore)
        quarter = try container.decodeIfPresent(Int.self, forKey: .quarter)
        timeRemaining = try container.decodeIfPresent(String.self, forKey: .timeRemaining)
        isLive = try container.decode(Bool.self, forKey: .isLive)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        startingLineups = try container.decodeIfPresent(StartingLineups.self, forKey: .startingLineups)
        boxScore = try container.decodeIfPresent(BoxScore.self, forKey: .boxScore)
        gameStats = try container.decodeIfPresent(GameStats.self, forKey: .gameStats)
        
        // Custom date parsing
        let gameDateString = try container.decode(String.self, forKey: .gameDate)
        let gameTimeString = try container.decode(String.self, forKey: .gameTime)
        
        // Parse gameDate (simple date string like "2025-04-13")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        gameDate = dateFormatter.date(from: gameDateString) ?? Date()
        
        // Parse gameTime (ISO datetime string like "2025-04-13T19:30:00.000Z")
        let isoFormatter = ISO8601DateFormatter()
        gameTime = isoFormatter.date(from: gameTimeString) ?? Date()
    }
    
    var displayTitle: String {
        return "\(awayTeam.name) vs. \(homeTeam.name)"
    }
    
    var leagueDisplayName: String {
        return league.name
    }
    
    // CodingKeys for custom decoding
    private enum CodingKeys: String, CodingKey {
        case id, homeTeam, awayTeam, league, season, week, gameDate, gameTime
        case venue, city, state, country, homeScore, awayScore
        case quarter, timeRemaining, isLive, isCompleted
        case startingLineups, boxScore, gameStats
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

