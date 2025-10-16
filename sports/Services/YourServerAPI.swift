//
//  YourServerAPI.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import Foundation

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

class YourServerAPI: ObservableObject {
    static let shared = YourServerAPI()
    
    // TODO: Update this URL when you deploy your server
    private let baseURL = "http://localhost:3000/api" // Change to your deployed server URL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Games
    func fetchGames(leagueId: String = "NBA", season: String? = nil) async throws -> [Game] {
        var urlComponents = URLComponents(string: "\(baseURL)/games")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "leagueId", value: leagueId)
        ]
        
        if let season = season {
            queryItems.append(URLQueryItem(name: "season", value: season))
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
        
        let apiResponse = try JSONDecoder().decode(YourServerGamesResponse.self, from: data)
        return apiResponse.data
    }

    // MARK: - Seasons
    func fetchSeasons(leagueId: String = "NBA") async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/leagues/\(leagueId)/seasons") else {
            throw APIError.invalidURL
        }
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        let apiResponse = try JSONDecoder().decode(YourServerSeasonsResponse.self, from: data)
        return apiResponse.data.seasons
    }
    
    // MARK: - Teams
    func fetchTeams(leagueId: String = "NBA") async throws -> [Team] {
        var urlComponents = URLComponents(string: "\(baseURL)/teams")!
        urlComponents.queryItems = [
            URLQueryItem(name: "leagueId", value: leagueId)
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(YourServerTeamsResponse.self, from: data)
        return apiResponse.data
    }
    
    // MARK: - Leagues
    func fetchLeagues() async throws -> [League] {
        guard let url = URL(string: "\(baseURL)/leagues") else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(YourServerLeaguesResponse.self, from: data)
        return apiResponse.data
    }
    
    // MARK: - Players
    func fetchPlayers(teamId: String? = nil, leagueId: String? = nil, position: String? = nil) async throws -> [Player] {
        var urlComponents = URLComponents(string: "\(baseURL)/players")!
        var queryItems: [URLQueryItem] = []
        
        if let teamId = teamId {
            queryItems.append(URLQueryItem(name: "teamId", value: teamId))
        }
        if let leagueId = leagueId {
            queryItems.append(URLQueryItem(name: "leagueId", value: leagueId))
        }
        if let position = position {
            queryItems.append(URLQueryItem(name: "position", value: position))
        }
        
        urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(YourServerPlayersResponse.self, from: data)
        return apiResponse.data
    }
    
    func fetchPlayer(playerId: String) async throws -> Player {
        guard let url = URL(string: "\(baseURL)/players/\(playerId)") else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(YourServerPlayerResponse.self, from: data)
        return apiResponse.data
    }
    
    func fetchTeamRoster(teamId: String) async throws -> [Player] {
        guard let url = URL(string: "\(baseURL)/players/team/\(teamId)") else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let apiResponse = try JSONDecoder().decode(YourServerTeamRosterResponse.self, from: data)
        return apiResponse.data
    }
    
    // MARK: - Player Stats
    func fetchPlayerStats(gameId: String, teamId: String? = nil) async throws -> [PlayerStats] {
        var urlComponents = URLComponents(string: "\(baseURL)/playerStats")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "gameId", value: gameId)
        ]
        
        if let teamId = teamId {
            queryItems.append(URLQueryItem(name: "teamId", value: teamId))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle case where no player stats exist for this game
        if httpResponse.statusCode == 200 {
            let apiResponse = try JSONDecoder().decode(YourServerPlayerStatsResponse.self, from: data)
            return apiResponse.data
        } else if httpResponse.statusCode == 404 {
            // No player stats found for this game - return empty array
            return []
        } else {
            throw APIError.invalidResponse
        }
    }
    
    func fetchPlayerStatsByGame(gameId: String) async throws -> [PlayerStats] {
        guard let url = URL(string: "\(baseURL)/playerStats/game/\(gameId)") else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle case where no player stats exist for this game
        if httpResponse.statusCode == 200 {
            let apiResponse = try JSONDecoder().decode(YourServerPlayerStatsResponse.self, from: data)
            return apiResponse.data
        } else if httpResponse.statusCode == 404 {
            // No player stats found for this game - return empty array
            return []
        } else {
            throw APIError.invalidResponse
        }
    }
    
    func fetchPlayerStatsByTeam(teamId: String, gameId: String? = nil) async throws -> [PlayerStats] {
        var urlComponents = URLComponents(string: "\(baseURL)/playerStats/team/\(teamId)")!
        
        if let gameId = gameId {
            urlComponents.queryItems = [
                URLQueryItem(name: "gameId", value: gameId)
            ]
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handle case where no player stats exist for this team/game
        if httpResponse.statusCode == 200 {
            let apiResponse = try JSONDecoder().decode(YourServerPlayerStatsResponse.self, from: data)
            return apiResponse.data
        } else if httpResponse.statusCode == 404 {
            // No player stats found - return empty array
            return []
        } else {
            throw APIError.invalidResponse
        }
    }
    
    func fetchPlayerStatsByPlayer(playerId: String) async throws -> [PlayerStats] {
        guard let url = URL(string: "\(baseURL)/playerStats/player/\(playerId)") else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let apiResponse = try JSONDecoder().decode(YourServerPlayerStatsResponse.self, from: data)
            return apiResponse.data
        } else if httpResponse.statusCode == 404 {
            return []
        } else {
            throw APIError.invalidResponse
        }
    }

    // MARK: - Single Game
    func fetchGame(gameId: String, leagueId: String? = nil) async throws -> Game? {
        var urlString = "\(baseURL)/games/\(gameId)"
        if let leagueId = leagueId, let encoded = leagueId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "?leagueId=\(encoded)"
        }
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if httpResponse.statusCode == 200 {
            let apiResponse = try JSONDecoder().decode(YourServerSingleGameResponse.self, from: data)
            return apiResponse.data
        } else if httpResponse.statusCode == 404 {
            return nil
        } else {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Data Refresh
    func refreshData(leagueId: String = "NBA", season: String = "2024-25 Regular") async throws -> RefreshResponse {
        guard let url = URL(string: "\(baseURL)/refresh") else {
            throw APIError.invalidURL
        }
        
        var request = createRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = RefreshRequest(leagueId: leagueId, season: season)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let refreshResponse = try JSONDecoder().decode(RefreshResponse.self, from: data)
        return refreshResponse
    }
    
    // MARK: - Server Status
    func getServerStatus() async throws -> ServerStatus {
        guard let url = URL(string: "\(baseURL)/status") else {
            throw APIError.invalidURL
        }
        
        let request = createRequest(url: url)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let statusResponse = try JSONDecoder().decode(YourServerStatusResponse.self, from: data)
        return statusResponse.data
    }
    
    // MARK: - Private Helpers
    private func createRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}

// MARK: - Response Models
struct YourServerGamesResponse: Codable {
    let success: Bool
    let data: [Game]
    let count: Int
    let leagueId: String
    let season: String
}

struct YourServerSingleGameResponse: Codable {
    let success: Bool
    let data: Game
}

struct YourServerTeamsResponse: Codable {
    let success: Bool
    let data: [Team]
    let dataByConference: [String: [Team]]
    let count: Int
    let leagueId: String
}

struct YourServerLeaguesResponse: Codable {
    let success: Bool
    let data: [League]
    let count: Int
}

struct YourServerSeasonsResponse: Codable {
    let success: Bool
    let data: SeasonsPayload
}

struct SeasonsPayload: Codable {
    let seasons: [String]
}

struct YourServerPlayersResponse: Codable {
    let success: Bool
    let data: [Player]
    let count: Int
    let filters: PlayerFilters
}

struct YourServerPlayerResponse: Codable {
    let success: Bool
    let data: Player
}

struct YourServerTeamRosterResponse: Codable {
    let success: Bool
    let data: [Player]
    let dataByPosition: [String: [Player]]
    let count: Int
    let teamId: String
}

struct PlayerFilters: Codable {
    let teamId: String?
    let leagueId: String?
    let position: String?
}

struct YourServerStatusResponse: Codable {
    let success: Bool
    let data: ServerStatus
}

struct RefreshRequest: Codable {
    let leagueId: String
    let season: String
}

struct RefreshResponse: Codable {
    let success: Bool
    let message: String
    let stats: RefreshStats?
    let error: String?
}

struct RefreshStats: Codable {
    let teams: Int
    let games: Int
    let league: String
}

struct ServerStatus: Codable {
    let server: ServerInfo
    let database: DatabaseStats
    let apiConnection: APIConnectionStatus
    let refreshStatus: RefreshStatusInfo
}

struct ServerInfo: Codable {
    let status: String
    let uptime: Double
    let environment: String
    let timestamp: String
}

struct DatabaseStats: Codable {
    let leaguesCount: Int
    let teamsCount: Int
    let gamesCount: Int
    let freshnessCount: Int
}

struct APIConnectionStatus: Codable {
    let success: Bool
    let message: String
    let error: String?
}

struct RefreshStatusInfo: Codable {
    let isRefreshing: Bool
    let lastRefresh: String
}
