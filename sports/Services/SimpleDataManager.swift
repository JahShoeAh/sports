//
//  SimpleDataManager.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import Foundation

class SimpleDataManager: ObservableObject {
    static let shared = SimpleDataManager()
    
    private var cachedGames: [String: [Game]] = [:]
    private var cachedTeams: [String: [Team]] = [:]
    private var lastUpdateTime: [String: Date] = [:]
    
    private init() {}
    
    // MARK: - Save Data
    func saveGames(_ games: [Game], for leagueId: String) {
        cachedGames[leagueId] = games
        lastUpdateTime[leagueId] = Date()
        print("Saved \(games.count) games for league \(leagueId)")
    }
    
    func saveTeams(_ teams: [Team], for leagueId: String) {
        cachedTeams[leagueId] = teams
        lastUpdateTime[leagueId] = Date()
        print("Saved \(teams.count) teams for league \(leagueId)")
    }
    
    // MARK: - Fetch Data
    func fetchGames(for leagueId: String, season: String? = nil) -> [Game] {
        guard let games = cachedGames[leagueId] else { return [] }
        
        if let season = season {
            return games.filter { $0.season == season }
        }
        
        return games
    }
    
    func fetchTeams(for leagueId: String) -> [Team] {
        return cachedTeams[leagueId] ?? []
    }
    
    // MARK: - Data Freshness
    func isDataFresh(for leagueId: String, maxAge: TimeInterval = 5 * 60) -> Bool { // 5 minutes for development
        guard let lastUpdate = lastUpdateTime[leagueId] else { return false }
        return Date().timeIntervalSince(lastUpdate) < maxAge
    }
    
    func getLastUpdateTime(for leagueId: String) -> Date? {
        return lastUpdateTime[leagueId]
    }
    
    // MARK: - Clear Data
    func clearData(for leagueId: String) {
        cachedGames.removeValue(forKey: leagueId)
        cachedTeams.removeValue(forKey: leagueId)
        lastUpdateTime.removeValue(forKey: leagueId)
        print("Cleared data for league \(leagueId)")
    }
    
    func clearAllData() {
        cachedGames.removeAll()
        cachedTeams.removeAll()
        lastUpdateTime.removeAll()
        print("Cleared all cached data")
    }
    
    // MARK: - Stats
    func getStats() -> (games: Int, teams: Int, leagues: Int) {
        let totalGames = cachedGames.values.flatMap { $0 }.count
        let totalTeams = cachedTeams.values.flatMap { $0 }.count
        let totalLeagues = cachedGames.keys.count
        return (totalGames, totalTeams, totalLeagues)
    }
}
