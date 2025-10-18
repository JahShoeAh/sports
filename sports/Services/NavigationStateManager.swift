//
//  NavigationStateManager.swift
//  sports
//
//  Created by Assistant on 1/15/25.
//

import SwiftUI

@MainActor
class NavigationStateManager: ObservableObject {
    static let shared = NavigationStateManager()
    
    private init() {}
    
    // Simple session tracking
    private var isInActiveSession = true
    
    // MARK: - Debug Logging
    private func debugLog(_ message: String) {
        print("[NavigationStateManager] \(message)")
    }
    
    func printCurrentState() {
        debugLog("=== Current Navigation State ===")
        debugLog("In active session: \(isInActiveSession)")
        debugLog("Team tabs: \(teamTabState)")
        debugLog("Player tabs: \(playerTabState)")
        debugLog("Game tabs: \(gameTabState)")
        debugLog("League tabs: \(leagueTabState)")
        debugLog("Team seasons: \(teamSeasonState)")
        debugLog("League seasons: \(leagueSeasonState)")
        debugLog("================================")
    }
    
    // MARK: - Session Management
    func endSession() {
        debugLog("endSession() - clearing all state")
        isInActiveSession = false
        clearAllState()
    }
    
    func startSession() {
        debugLog("startSession() - beginning new session")
        isInActiveSession = true
    }
    
    func clearAllState() {
        debugLog("clearAllState() - clearing all navigation state")
        teamTabState.removeAll()
        teamSeasonState.removeAll()
        teamOpponentFilters.removeAll()
        teamHomeAwayFilters.removeAll()
        teamWinLossFilters.removeAll()
        playerTabState.removeAll()
        playerSeasonState.removeAll()
        collapsedMonths.removeAll()
        gameTabState.removeAll()
        leagueTabState.removeAll()
        leagueSeasonState.removeAll()
        leagueTeamFilters.removeAll()
    }
    
    // MARK: - Team State
    private var teamTabState: [String: Int] = [:]
    private var teamSeasonState: [String: String] = [:]
    private var teamOpponentFilters: [String: (selected: Set<String>, excluded: Set<String>)] = [:]
    private var teamHomeAwayFilters: [String: String] = [:]
    private var teamWinLossFilters: [String: String] = [:]
    
    // MARK: - Player State
    private var playerTabState: [String: Int] = [:]
    private var playerSeasonState: [String: String] = [:]
    private var collapsedMonths: [String: Set<String>] = [:]
    
    // MARK: - Game State
    private var gameTabState: [String: Int] = [:]
    
    // MARK: - League State
    private var leagueTabState: [String: String] = [:] // "schedule" or "teams"
    private var leagueSeasonState: [String: String] = [:]
    private var leagueTeamFilters: [String: (selected: Set<String>, excluded: Set<String>)] = [:]
    
    // MARK: - Team Methods
    func getTeamTab(teamId: String) -> Int {
        let tab = teamTabState[teamId] ?? 0
        debugLog("getTeamTab(\(teamId)) -> \(tab)")
        return tab
    }
    
    func setTeamTab(teamId: String, tab: Int) {
        debugLog("setTeamTab(\(teamId), \(tab))")
        teamTabState[teamId] = tab
    }
    
    func getTeamSeason(teamId: String) -> String {
        return teamSeasonState[teamId] ?? ""
    }
    
    func setTeamSeason(teamId: String, season: String) {
        teamSeasonState[teamId] = season
    }
    
    func getTeamOpponentFilters(teamId: String) -> (selected: Set<String>, excluded: Set<String>) {
        return teamOpponentFilters[teamId] ?? (selected: [], excluded: [])
    }
    
    func setTeamOpponentFilters(teamId: String, selected: Set<String>, excluded: Set<String>) {
        teamOpponentFilters[teamId] = (selected: selected, excluded: excluded)
    }
    
    func getTeamHomeAwayFilter(teamId: String) -> String {
        return teamHomeAwayFilters[teamId] ?? "either"
    }
    
    func setTeamHomeAwayFilter(teamId: String, filter: String) {
        teamHomeAwayFilters[teamId] = filter
    }
    
    func getTeamWinLossFilter(teamId: String) -> String {
        return teamWinLossFilters[teamId] ?? "either"
    }
    
    func setTeamWinLossFilter(teamId: String, filter: String) {
        teamWinLossFilters[teamId] = filter
    }
    
    func clearTeamState(teamId: String) {
        debugLog("clearTeamState(\(teamId)) - clearing all team state")
        teamTabState.removeValue(forKey: teamId)
        teamSeasonState.removeValue(forKey: teamId)
        teamOpponentFilters.removeValue(forKey: teamId)
        teamHomeAwayFilters.removeValue(forKey: teamId)
        teamWinLossFilters.removeValue(forKey: teamId)
    }
    
    // MARK: - Player Methods
    func getPlayerTab(playerId: String) -> Int {
        return playerTabState[playerId] ?? 0
    }
    
    func setPlayerTab(playerId: String, tab: Int) {
        playerTabState[playerId] = tab
    }
    
    func getPlayerSeason(playerId: String) -> String {
        return playerSeasonState[playerId] ?? ""
    }
    
    func setPlayerSeason(playerId: String, season: String) {
        playerSeasonState[playerId] = season
    }
    
    func getCollapsedMonths(playerId: String) -> Set<String> {
        return collapsedMonths[playerId] ?? []
    }
    
    func setCollapsedMonths(playerId: String, months: Set<String>) {
        collapsedMonths[playerId] = months
    }
    
    func clearPlayerState(playerId: String) {
        playerTabState.removeValue(forKey: playerId)
        playerSeasonState.removeValue(forKey: playerId)
        collapsedMonths.removeValue(forKey: playerId)
    }
    
    // MARK: - Game Methods
    func getGameTab(gameId: String) -> Int {
        return gameTabState[gameId] ?? 0
    }
    
    func setGameTab(gameId: String, tab: Int) {
        gameTabState[gameId] = tab
    }
    
    func clearGameState(gameId: String) {
        gameTabState.removeValue(forKey: gameId)
    }
    
    // MARK: - League Methods
    func getLeagueTab(leagueId: String) -> String {
        return leagueTabState[leagueId] ?? "schedule"
    }
    
    func setLeagueTab(leagueId: String, tab: String) {
        leagueTabState[leagueId] = tab
    }
    
    func getLeagueSeason(leagueId: String) -> String {
        return leagueSeasonState[leagueId] ?? ""
    }
    
    func setLeagueSeason(leagueId: String, season: String) {
        leagueSeasonState[leagueId] = season
    }
    
    func getLeagueTeamFilters(leagueId: String) -> (selected: Set<String>, excluded: Set<String>) {
        return leagueTeamFilters[leagueId] ?? (selected: [], excluded: [])
    }
    
    func setLeagueTeamFilters(leagueId: String, selected: Set<String>, excluded: Set<String>) {
        leagueTeamFilters[leagueId] = (selected: selected, excluded: excluded)
    }
    
    func clearLeagueState(leagueId: String) {
        leagueTabState.removeValue(forKey: leagueId)
        leagueSeasonState.removeValue(forKey: leagueId)
        leagueTeamFilters.removeValue(forKey: leagueId)
    }
}
