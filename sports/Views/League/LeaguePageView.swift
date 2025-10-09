//
//  LeaguePageView.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import SwiftUI

struct LeaguePageView: View {
    let league: League
    @State private var selectedTab: LeagueTab = .schedule
    @State private var selectedSeason: String = "2024-25 Regular"
    @State private var games: [Game] = []
    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var errorMessage: String?
    @State private var lastUpdateTime: Date?
    
    private let dataManager = SimpleDataManager.shared
    private let cacheService = CacheService.shared
    private let yourServerAPI = YourServerAPI.shared
    
    enum LeagueTab: String, CaseIterable {
        case schedule = "Schedule"
        case teams = "Teams"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // League Header
            VStack(spacing: 8) {
                HStack {
                    if let logoURL = league.logoURL {
                        AsyncImage(url: URL(string: logoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                        }
                        .frame(width: 40, height: 40)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(league.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(league.level.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Season Selector and Refresh Button (only show on schedule tab)
                if selectedTab == .schedule {
                    HStack {
                        Text("Season:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Season", selection: $selectedSeason) {
                            Text("2025 Playoffs").tag("2025 Playoffs")
                            Text("2024-25 Regular").tag("2024-25 Regular")
                            Text("2023-24 Regular").tag("2023-24 Regular")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedSeason) { _, newSeason in
                            loadGames(season: newSeason)
                        }
                        
                        Spacer()
                        
                        // Refresh Button
                        Button(action: {
                            Task {
                                await refreshData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        .disabled(isRefreshing)
                        
                        // Last Update Time
                        if let lastUpdate = lastUpdateTime {
                            Text("Updated \(formatLastUpdate(lastUpdate))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(LeagueTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.primary : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .background(Color(.systemBackground))
            
            Divider()
            
            // Content
            Group {
                switch selectedTab {
                case .schedule:
                    GameScheduleView(
                        games: games,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        onGameTap: { game in
                            // TODO: Navigate to GameMenuView
                            print("Tapped game: \(game.displayTitle)")
                        }
                    )
                case .teams:
                    TeamsView(
                        teams: teams,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        onTeamTap: { team in
                            // TODO: Navigate to TeamMenuView
                            print("Tapped team: \(team.fullName)")
                        }
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInitialData()
        }
        .refreshable {
            await refreshData()
        }
    }
    
    private func loadInitialData() async {
        // First, try to load from cache
        loadCachedData()
        
        // Then check if we need to refresh data
        await cacheService.refreshDataIfNeeded(for: league.id)
        
        // Reload from cache after potential refresh
        loadCachedData()
    }
    
    private func loadCachedData() {
        // Load games from cache
        games = dataManager.fetchGames(for: league.id, season: selectedSeason)
        
        // Load teams from cache
        teams = dataManager.fetchTeams(for: league.id)
        
        // Update last update time
        lastUpdateTime = cacheService.getLastUpdateTime(for: league.id)
        
        // Clear any previous errors
        errorMessage = nil
    }
    
    private func loadGames(season: String) {
        // Load games from cache for the selected season
        games = dataManager.fetchGames(for: league.id, season: season)
        
        // If no games found in cache for this season, try to fetch from server
        if games.isEmpty {
            Task {
                await fetchGamesFromServer(season: season)
            }
        }
    }
    
    private func fetchGamesFromServer(season: String) async {
        do {
            let fetchedGames = try await yourServerAPI.fetchGames(leagueId: league.id, season: season)
            dataManager.saveGames(fetchedGames, for: league.id)
            
            await MainActor.run {
                games = dataManager.fetchGames(for: league.id, season: season)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load games: \(error.localizedDescription)"
            }
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        errorMessage = nil
        
        // Clear cache and force refresh
        dataManager.clearData(for: league.id)
        
        // Fetch fresh data from server
        await fetchGamesFromServer(season: selectedSeason)
        
        // Also fetch teams
        do {
            let teams = try await yourServerAPI.fetchTeams(leagueId: league.id)
            dataManager.saveTeams(teams, for: league.id)
        } catch {
            print("Error fetching teams: \(error)")
        }
        
        await MainActor.run {
            loadCachedData()
            isRefreshing = false
        }
    }
    
    private func formatLastUpdate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationView {
        LeaguePageView(league: League(
            id: "NFL",
            name: "National Football League",
            abbreviation: "NFL",
            logoURL: nil,
            sport: .football,
            level: .professional,
            isActive: true
        ))
    }
}
