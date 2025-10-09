//
//  CacheService.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import Foundation
import BackgroundTasks

class CacheService: ObservableObject {
    static let shared = CacheService()
    
    private let dataManager = SimpleDataManager.shared
    private let yourServerAPI = YourServerAPI.shared
    
    private init() {}
    
    // MARK: - Public Methods
    func refreshDataIfNeeded(for leagueId: String) async {
        // Check if data is fresh (less than 24 hours old)
        guard !dataManager.isDataFresh(for: leagueId) else {
            print("Data is fresh for league \(leagueId), skipping refresh")
            return
        }
        
        print("Refreshing data for league \(leagueId)")
        await refreshLeagueData(leagueId: leagueId)
    }
    
    func refreshAllData() async {
        print("Refreshing all cached data")
        
        // Refresh NFL data
        await refreshLeagueData(leagueId: "NFL")
        
        // Add other leagues as needed
        await refreshLeagueData(leagueId: "NBA") // NBA
        // await refreshLeagueData(leagueId: "3") // MLB
    }
    
    func forceRefreshData(for leagueId: String) async {
        print("Force refreshing data for league \(leagueId)")
        await refreshLeagueData(leagueId: leagueId)
    }
    
    // MARK: - Private Methods
    private func refreshLeagueData(leagueId: String) async {
        do {
            // Fetch and save teams from your server
            let teams = try await yourServerAPI.fetchTeams(leagueId: leagueId)
            dataManager.saveTeams(teams, for: leagueId)
            
            // Fetch and save games for current season from your server
            let currentSeason = leagueId == "NBA" ? "2024-25 Regular" : "2025"
            let games = try await yourServerAPI.fetchGames(leagueId: leagueId, season: currentSeason)
            dataManager.saveGames(games, for: leagueId)
            
        } catch {
            print("Error refreshing data for league \(leagueId): \(error)")
        }
    }
    
    // MARK: - Background Tasks
    func registerBackgroundTasks() {
        // Register background app refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.sports.refresh", using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule the next background refresh
        scheduleBackgroundRefresh()
        
        // Perform the refresh
        Task {
            await refreshAllData()
            task.setTaskCompleted(success: true)
        }
        
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
    }
    
    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.sports.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24 hours from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled")
        } catch {
            print("Could not schedule background refresh: \(error)")
        }
    }
    
    // MARK: - Manual Refresh
    func manualRefresh(for leagueId: String) async -> Bool {
        do {
            // Try to refresh from your server first
            let refreshResponse = try await yourServerAPI.refreshData(leagueId: leagueId)
            if refreshResponse.success {
                // Server refresh successful, now update local cache
                await forceRefreshData(for: leagueId)
                return true
            } else {
                print("Server refresh failed: \(refreshResponse.message)")
                return false
            }
        } catch {
            print("Manual refresh failed: \(error)")
            return false
        }
    }
    
    // MARK: - Data Status
    func getDataStatus(for leagueId: String) -> DataStatus {
        if dataManager.isDataFresh(for: leagueId) {
            return .fresh
        } else {
            return .stale
        }
    }
    
    func getLastUpdateTime(for leagueId: String) -> Date? {
        return dataManager.getLastUpdateTime(for: leagueId)
    }
}

enum DataStatus {
    case fresh
    case stale
    case empty
}
