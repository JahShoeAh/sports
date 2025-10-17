//
//  AthleteMenuView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct AthleteMenuView: View {
    let player: Player
    @State private var selectedTab = 0
    @State private var selectedSeason: String = ""
    @State private var availableSeasons: [String] = []
    @State private var pastGames: [Game] = []
    @State private var allStats: [PlayerStats] = []
    @State private var filteredStats: [(stat: PlayerStats, game: Game)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let dataManager = SimpleDataManager.shared
    private let cacheService = CacheService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Player Header
            PlayerHeaderView(player: player)
                .padding()
            
            // Tab Picker
            Picker("Player Details", selection: $selectedTab) {
                Text("Past Games").tag(0)
                Text("Stats").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Tab Content
            if selectedTab == 0 {
                PlayerPastGamesView(player: player, pastGames: $pastGames, isLoading: $isLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PlayerStatsView(
                    player: player,
                    selectedSeason: $selectedSeason,
                    availableSeasons: $availableSeasons,
                    filteredStats: $filteredStats,
                    isLoading: $isLoading
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPlayerData()
        }
        .onChange(of: selectedSeason) { _, _ in
            applySeasonFilter()
        }
    }
    
    private func loadPlayerData() async {
        isLoading = true
        errorMessage = nil
        
        let leagueId = player.team?.league.id ?? "NBA"
        
        // 1) Seed from cache for games if available
        var gameIdToGame: [String: Game] = [:]
        let cachedGames = dataManager.fetchGames(for: leagueId)
        for game in cachedGames { gameIdToGame[game.id] = game }
        
        // 2) Kick off cache refresh in background
        await cacheService.refreshDataIfNeeded(for: leagueId)
        
        // 3) Fetch stats and ensure game mapping, with retries
        do {
            let statsForPlayer = try await fetchPlayerStatsByPlayerWithRetry(playerId: player.id)
            let nonZeroStats = statsForPlayer.filter { minutesToSeconds($0.min) > 0 }
            
            // Ensure we have game objects for each stat (use cache first, then fetch missing)
            for stat in nonZeroStats where gameIdToGame[stat.gameId] == nil {
                if let fetched = try await YourServerAPI.shared.fetchGame(gameId: stat.gameId, leagueId: leagueId) {
                    gameIdToGame[fetched.id] = fetched
                }
            }
            
            let joined: [(PlayerStats, Game)] = nonZeroStats.compactMap { stat in
                guard let game = gameIdToGame[stat.gameId] else { return nil }
                return (stat, game)
            }
            let sorted = joined.sorted { $0.1.gameTime < $1.1.gameTime }
            let seasons = Array(Set(sorted.map { $0.1.season })).sorted()
            
            await MainActor.run {
                self.pastGames = sorted.map { $0.1 }
                self.allStats = nonZeroStats
                self.availableSeasons = seasons
                self.selectedSeason = seasons.last ?? ""
                self.isLoading = false
                self.applySeasonFilter()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load player data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func fetchPlayerStatsByPlayerWithRetry(playerId: String, maxRetries: Int = 2) async throws -> [PlayerStats] {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do { return try await YourServerAPI.shared.fetchPlayerStatsByPlayer(playerId: playerId) }
            catch {
                lastError = error
                if attempt < maxRetries { try? await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1))) }
            }
        }
        throw lastError ?? APIError.networkError("Unknown error")
    }
    
    private func applySeasonFilter() {
        guard !selectedSeason.isEmpty else {
            filteredStats = []
            return
        }
        var gameIdToGame: [String: Game] = [:]
        for game in pastGames { gameIdToGame[game.id] = game }
        let pairs: [(PlayerStats, Game)] = allStats.compactMap { stat in
            guard let game = gameIdToGame[stat.gameId], game.season == selectedSeason else { return nil }
            return (stat, game)
        }
        filteredStats = pairs.sorted { $0.1.gameTime < $1.1.gameTime }
    }
    
    private func minutesToSeconds(_ minString: String) -> Int {
        // Accept "MM:SS", "M:SS", numbers-only (minutes), and ignore non-numeric like "DNP"
        if minString.contains(":") {
            let parts = minString.split(separator: ":").map(String.init)
            guard parts.count == 2, let m = Int(parts[0]), let s = Int(parts[1]) else { return 0 }
            return m * 60 + s
        } else if let minutes = Int(minString) {
            return minutes * 60
        } else {
            return 0
        }
    }
}

struct PlayerHeaderView: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Player Headshot
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(player.positionString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let team = player.team {
                        NavigationLink(destination: TeamMenuLoaderView(teamId: team.id)) {
                            Text(team.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Text("Age: \(player.ageString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Height: \(player.heightString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Weight: \(player.weightString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct PlayerPastGamesView: View {
    let player: Player
    @Binding var pastGames: [Game]
    @Binding var isLoading: Bool
    @State private var collapsedMonths: Set<String> = []
    
    private func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private var gamesByMonth: [String: [Game]] {
        var grouped: [String: [Game]] = [:]
        for game in pastGames {
            let key = monthKey(for: game.gameTime)
            grouped[key, default: []].append(game)
        }
        for key in grouped.keys {
            grouped[key]?.sort { $0.gameTime < $1.gameTime }
        }
        return grouped
    }
    
    private var sortedMonthKeys: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return gamesByMonth.keys.sorted { a, b in
            if let da = formatter.date(from: a), let db = formatter.date(from: b) {
                return da < db
            }
            return a < b
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading {
                ProgressView("Loading past games...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if pastGames.isEmpty {
                VStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No past games available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(sortedMonthKeys, id: \.self) { month in
                            VStack(alignment: .leading, spacing: 12) {
                                Button(action: {
                                    if collapsedMonths.contains(month) { collapsedMonths.remove(month) } else { collapsedMonths.insert(month) }
                                }) {
                                    HStack {
                                        Image(systemName: collapsedMonths.contains(month) ? "chevron.right" : "chevron.down")
                                            .foregroundColor(.secondary)
                                        Text(month)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("\(gamesByMonth[month]?.count ?? 0) games")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                
                                if !collapsedMonths.contains(month) {
                                    LazyVStack(spacing: 12) {
                                        ForEach(gamesByMonth[month] ?? []) { game in
                                            GameCardAthlete(game: game, athleteTeam: player.team ?? getTeamFromGame(game, playerTeamId: player.teamId))
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }
    
    private func getTeamFromGame(_ game: Game, playerTeamId: String) -> Team {
        // If player's team matches home team, return home team, otherwise return away team
        if game.homeTeam.id == playerTeamId {
            return game.homeTeam
        } else {
            return game.awayTeam
        }
    }
}

struct PlayerStatsView: View {
    let player: Player
    @Binding var selectedSeason: String
    @Binding var availableSeasons: [String]
    @Binding var filteredStats: [(stat: PlayerStats, game: Game)]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Season Selector
            HStack {
                Picker("Season", selection: $selectedSeason) {
                    ForEach(availableSeasons, id: \.self) { season in
                        Text(season).tag(season)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            
            // Stats Table
            if isLoading {
                ProgressView("Loading stats...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredStats.isEmpty {
                VStack {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No stats available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    PlayerStatsTableView(rows: filteredStats)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

struct PlayerStatsTableView: View {
    let rows: [(stat: PlayerStats, game: Game)]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("DATE").font(.caption).fontWeight(.semibold).frame(width: 50, alignment: .leading)
                Text("TEAM").font(.caption).fontWeight(.semibold).frame(width: 52, alignment: .leading)
                Text("OPP").font(.caption).fontWeight(.semibold).frame(width: 52, alignment: .leading)
                Text("MIN").font(.caption).fontWeight(.semibold).frame(width: 36)
                Text("PTS").font(.caption).fontWeight(.semibold).frame(width: 36)
                Text("REB").font(.caption).fontWeight(.semibold).frame(width: 36)
                Text("AST").font(.caption).fontWeight(.semibold).frame(width: 36)
                Text("STL").font(.caption).fontWeight(.semibold).frame(width: 36)
                Text("BLK").font(.caption).fontWeight(.semibold).frame(width: 36)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(formattedDate(row.game.gameTime))
                        .font(.caption)
                        .frame(width: 50, alignment: .leading)
                    
                    NavigationLink(destination: GameMenuView(game: row.game)) {
                        Text(teamAbbrev(for: row.game, stat: row.stat))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 52, alignment: .leading)
                    
                    NavigationLink(destination: GameMenuView(game: row.game)) {
                        Text(opponentDisplay(for: row.game, playerTeamId: row.stat.teamId))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 52, alignment: .leading)
                    
                    Text(row.stat.min).font(.caption).frame(width: 36)
                    Text("\(row.stat.points)").font(.caption).frame(width: 36)
                    Text("\(row.stat.totReb)").font(.caption).frame(width: 36)
                    Text("\(row.stat.assists)").font(.caption).frame(width: 36)
                    Text("\(row.stat.steals)").font(.caption).frame(width: 36)
                    Text("\(row.stat.blocks)").font(.caption).frame(width: 36)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                if row.stat.id != rows.last?.stat.id {
                    Divider().padding(.horizontal, 12)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func teamAbbrev(for game: Game, stat: PlayerStats) -> String {
        let statAbbrev = stat.team.abbreviation
        if !statAbbrev.trimmingCharacters(in: .whitespaces).isEmpty {
            return statAbbrev
        }
        if game.homeTeam.id == stat.teamId {
            return game.homeTeam.abbreviation ?? game.homeTeam.name
        }
        if game.awayTeam.id == stat.teamId {
            return game.awayTeam.abbreviation ?? game.awayTeam.name
        }
        return stat.teamId
    }

    private func opponentDisplay(for game: Game, playerTeamId: String) -> String {
        let isHome = game.homeTeam.id == playerTeamId
        let opponent = isHome ? game.awayTeam : game.homeTeam
        let prefix = isHome ? "vs" : "@"
        return "\(prefix) \(opponent.abbreviation ?? opponent.name)"
    }
}
