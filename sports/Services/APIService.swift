//
//  APIService.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://v1.american-football.api-sports.io"
    private let apiKey = "YOUR_API_KEY" // TODO:QUESTION - Add API key configuration
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - NFL Games
    func fetchNFLGames(season: String = "2025", week: Int? = nil) async throws -> [Game] {
        var urlComponents = URLComponents(string: "\(baseURL)/games")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "season", value: season),
            URLQueryItem(name: "league", value: "1") // NFL league ID
        ]
        
        if let week = week {
            queryItems.append(URLQueryItem(name: "week", value: String(week)))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(NFLGamesResponse.self, from: data)
        return apiResponse.response.map { $0.toGame() }
    }
    
    // MARK: - NFL Teams
    func fetchNFLTeams() async throws -> [Team] {
        let urlComponents = URLComponents(string: "\(baseURL)/teams")!
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(NFLTeamsResponse.self, from: data)
        return apiResponse.response.map { $0.toTeam() }
    }
    
    // MARK: - NFL Players
    func fetchNFLPlayers(teamId: String? = nil) async throws -> [Player] {
        var urlComponents = URLComponents(string: "\(baseURL)/players")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "league", value: "1"), // NFL league ID
            URLQueryItem(name: "season", value: "2025")
        ]
        
        if let teamId = teamId {
            queryItems.append(URLQueryItem(name: "team", value: teamId))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(NFLPlayersResponse.self, from: data)
        return apiResponse.response.map { $0.toPlayer() }
    }
    
    // MARK: - Game Statistics
    func fetchGameStatistics(gameId: String) async throws -> GameStats {
        let urlComponents = URLComponents(string: "\(baseURL)/games/statistics")!
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(NFLGameStatsResponse.self, from: data)
        return apiResponse.response.toGameStats()
    }
    
    // MARK: - Private Helpers
    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("v1.american-football.api-sports.io", forHTTPHeaderField: "X-RapidAPI-Host")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

// MARK: - API Response Models
struct NFLGamesResponse: Codable {
    let response: [NFLGameResponse]
}

struct NFLGameResponse: Codable {
    let game: NFLGame
    let teams: NFLTeams
    let scores: NFLScores?
    
    func toGame() -> Game {
        return Game(
            id: String(game.id),
            homeTeam: teams.home.toTeam(),
            awayTeam: teams.away.toTeam(),
            league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true),
            season: "2025",
            week: game.week,
            gameDate: game.date,
            gameTime: game.date,
            venue: game.venue?.name ?? "Unknown",
            city: game.venue?.city ?? "Unknown",
            state: game.venue?.state ?? "Unknown",
            country: game.venue?.country ?? "USA",
            status: GameStatus(rawValue: game.status.short) ?? .scheduled,
            homeScore: scores?.home.total,
            awayScore: scores?.away.total,
            quarter: scores?.home.quarter?.count,
            timeRemaining: game.status.timer,
            isLive: game.status.short == "live",
            isCompleted: game.status.short == "finished",
            startingLineups: nil,
            boxScore: nil,
            gameStats: nil
        )
    }
}

struct NFLGame: Codable {
    let id: Int
    let date: Date
    let week: Int?
    let status: NFLGameStatus
    let venue: NFLVenue?
}

struct NFLGameStatus: Codable {
    let short: String
    let timer: String?
}

struct NFLVenue: Codable {
    let name: String
    let city: String
    let state: String
    let country: String
}

struct NFLTeams: Codable {
    let home: NFLTeam
    let away: NFLTeam
}

struct NFLTeam: Codable {
    let id: Int
    let name: String
    let logo: String?
    
    func toTeam() -> Team {
        return Team(
            id: String(id),
            name: name,
            city: name, // TODO:QUESTION - Parse city from team name or get from API
            abbreviation: name, // TODO:QUESTION - Get proper abbreviation from API
            logoURL: logo,
            league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true),
            conference: nil, // TODO:QUESTION - Get conference info from API
            division: nil, // TODO:QUESTION - Get division info from API
            colors: nil
        )
    }
}

struct NFLScores: Codable {
    let home: NFLScore
    let away: NFLScore
}

struct NFLScore: Codable {
    let total: Int?
    let quarter: [Int]?
}

struct NFLTeamsResponse: Codable {
    let response: [NFLTeamResponse]
}

struct NFLTeamResponse: Codable {
    let team: NFLTeam
    let season: [NFLSeason]?
    
    func toTeam() -> Team {
        return team.toTeam()
    }
}

struct NFLSeason: Codable {
    let year: Int
    let start: String
    let end: String
}

struct NFLPlayersResponse: Codable {
    let response: [NFLPlayerResponse]
}

struct NFLPlayerResponse: Codable {
    let player: NFLPlayer
    let statistics: [NFLPlayerStats]?
    
    func toPlayer() -> Player {
        return Player(
            id: String(player.id),
            name: "\(player.firstname) \(player.lastname)",
            firstName: player.firstname,
            lastName: player.lastname,
            jerseyNumber: nil, // TODO:QUESTION - Get jersey number from statistics
            position: player.position,
            height: player.height,
            weight: player.weight,
            age: player.age,
            birthDate: nil, // TODO:QUESTION - Parse birth date from API
            birthPlace: player.birth?.place,
            currentTeam: nil, // TODO:QUESTION - Get current team from statistics
            headshotURL: player.photo,
            isActive: true,
            careerStats: [:]
        )
    }
}

struct NFLPlayer: Codable {
    let id: Int
    let name: String
    let firstname: String
    let lastname: String
    let position: String
    let height: String?
    let weight: Int?
    let age: Int?
    let birth: NFLBirth?
    let photo: String?
}

struct NFLBirth: Codable {
    let date: String?
    let place: String?
}

struct NFLPlayerStats: Codable {
    let team: NFLTeam
    let games: NFLPlayerGameStats
}

struct NFLPlayerGameStats: Codable {
    let played: Int?
    let starts: Int?
    let minutes: Int?
}

struct NFLGameStatsResponse: Codable {
    let response: NFLGameStatsData
}

struct NFLGameStatsData: Codable {
    let game: NFLGame
    let teams: [NFLTeamStats]
    
    func toGameStats() -> GameStats {
        // TODO:QUESTION - Implement proper game stats conversion
        return GameStats(home: TeamGameStats(team: Team(id: "", name: "", city: "", abbreviation: "", logoURL: nil, league: League(id: "", name: "", abbreviation: "", logoURL: nil, sport: .football, level: .professional, season: "", isActive: true), conference: nil, division: nil, colors: nil), statLeaders: []), away: TeamGameStats(team: Team(id: "", name: "", city: "", abbreviation: "", logoURL: nil, league: League(id: "", name: "", abbreviation: "", logoURL: nil, sport: .football, level: .professional, season: "", isActive: true), conference: nil, division: nil, colors: nil), statLeaders: []))
    }
}

struct NFLTeamStats: Codable {
    let team: NFLTeam
    let statistics: [NFLStatistic]
}

struct NFLStatistic: Codable {
    let type: String
    let value: String
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
}
