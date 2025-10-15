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
    let venue: Venue?
    let homeScore: Int?
    let awayScore: Int?
    let homeLineScore: [Int]?
    let awayLineScore: [Int]?
    let leadChanges: Int?
    let quarter: Int?
    let isLive: Bool
    let isCompleted: Bool
    let apiGameId: Int?
    
    // Game details
    let startingLineups: StartingLineups?
    
    // Default memberwise initializer
    init(id: String, homeTeam: Team, awayTeam: Team, league: League, season: String, week: Int?, gameDate: Date, gameTime: Date, venue: Venue?, homeScore: Int?, awayScore: Int?, homeLineScore: [Int]?, awayLineScore: [Int]?, leadChanges: Int?, quarter: Int?, isLive: Bool, isCompleted: Bool, apiGameId: Int?, startingLineups: StartingLineups?) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.league = league
        self.season = season
        self.week = week
        self.gameDate = gameDate
        self.gameTime = gameTime
        self.venue = venue
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.homeLineScore = homeLineScore
        self.awayLineScore = awayLineScore
        self.leadChanges = leadChanges
        self.quarter = quarter
        self.isLive = isLive
        self.isCompleted = isCompleted
        self.apiGameId = apiGameId
        self.startingLineups = startingLineups
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
        venue = try container.decodeIfPresent(Venue.self, forKey: .venue)
        homeScore = try container.decodeIfPresent(Int.self, forKey: .homeScore)
        awayScore = try container.decodeIfPresent(Int.self, forKey: .awayScore)
        homeLineScore = try container.decodeIfPresent([Int].self, forKey: .homeLineScore)
        awayLineScore = try container.decodeIfPresent([Int].self, forKey: .awayLineScore)
        leadChanges = try container.decodeIfPresent(Int.self, forKey: .leadChanges)
        quarter = try container.decodeIfPresent(Int.self, forKey: .quarter)
        isLive = try container.decode(Bool.self, forKey: .isLive)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        apiGameId = try container.decodeIfPresent(Int.self, forKey: .apiGameId)
        startingLineups = try container.decodeIfPresent(StartingLineups.self, forKey: .startingLineups)
        
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
        case venue, homeScore, awayScore, homeLineScore, awayLineScore, leadChanges
        case quarter, isLive, isCompleted
        case apiGameId
        case startingLineups
    }
}

struct StartingLineups: Codable {
    let home: [Player]
    let away: [Player]
}

// Removed BoxScore storage from model per backend change


