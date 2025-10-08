//
//  YourServerAPI.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import Foundation

class YourServerAPI: ObservableObject {
    static let shared = YourServerAPI()
    
    // TODO: Update this URL when you deploy your server
    private let baseURL = "http://localhost:3000/api" // Change to your deployed server URL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Games
    func fetchGames(leagueId: String = "1", season: String? = nil) async throws -> [Game] {
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
    
    // MARK: - Teams
    func fetchTeams(leagueId: String = "1") async throws -> [Team] {
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
    
    // MARK: - Data Refresh
    func refreshData(leagueId: String = "1", season: String = "2023") async throws -> RefreshResponse {
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
