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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Player Header
                PlayerHeaderView(player: player)
                
                // Tab View
                VStack(spacing: 0) {
                    // Tab Picker
                    Picker("Player Details", selection: $selectedTab) {
                        Text("Past Games").tag(0)
                        Text("Stats").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        PlayerPastGamesView(player: player, pastGames: $pastGames, isLoading: $isLoading)
                            .tag(0)
                        
                        PlayerStatsView(
                            player: player,
                            selectedSeason: $selectedSeason,
                            availableSeasons: $availableSeasons,
                            filteredStats: $filteredStats,
                            isLoading: $isLoading
                        )
                        .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 400)
                }
            }
            .padding()
        }
        .navigationTitle(player.displayName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadPlayerData()
        }
        .onChange(of: selectedSeason) { _ in
            applySeasonFilter()
        }
    }
    
    private func loadPlayerData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let leagueId = player.team?.league.id ?? "NBA"
            let games = try await YourServerAPI.shared.fetchGames(leagueId: leagueId)
            let statsForPlayer = try await YourServerAPI.shared.fetchPlayerStatsByPlayer(playerId: player.id)
            
            let nonZeroStats = statsForPlayer.filter { minutesToSeconds($0.min) > 0 }
            
            var gameIdToGame: [String: Game] = [:]
            for game in games { gameIdToGame[game.id] = game }
            
            var joined: [(PlayerStats, Game)] = []
            for stat in nonZeroStats {
                if let game = gameIdToGame[stat.gameId] {
                    joined.append((stat, game))
                } else {
                    // Fallback: fetch single game (covers games outside initially fetched season set)
                    if let fetched = try await YourServerAPI.shared.fetchGame(gameId: stat.gameId, leagueId: leagueId) {
                        gameIdToGame[fetched.id] = fetched
                        joined.append((stat, fetched))
                    }
                }
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
                        Text(team.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Past Games")
                .font(.headline)
                .fontWeight(.semibold)
            
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
                // 3-per-row grid for past games
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(pastGames) { game in
                        GamePosterCard(game: game)
                    }
                }
            }
        }
        .padding()
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
            // Season and Team Selectors
            VStack(spacing: 12) {
                HStack {
                    Text("Season:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Season", selection: $selectedSeason) {
                        ForEach(availableSeasons, id: \.self) { season in
                            Text(season).tag(season)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Spacer()
                }
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
                PlayerStatsTableView(rows: filteredStats)
            }
        }
        .padding()
    }
}

struct PlayerStatsTableView: View {
    let rows: [(stat: PlayerStats, game: Game)]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Date").font(.caption).fontWeight(.semibold).frame(width: 72, alignment: .leading)
                Text("Opponent").font(.caption).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
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
                    Text(row.game.gameTime, style: .date)
                        .font(.caption)
                        .frame(width: 72, alignment: .leading)
                    Text(opponentName(for: row.game, playerTeamId: row.stat.teamId))
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private func opponentName(for game: Game, playerTeamId: String) -> String {
        if game.homeTeam.id == playerTeamId { return game.awayTeam.name }
        return game.homeTeam.name
    }
}
