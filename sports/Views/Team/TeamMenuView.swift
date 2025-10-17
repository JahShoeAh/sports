//
//  TeamMenuView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct TeamMenuView: View {
    let team: Team
    @State private var selectedTab = 0
    @State private var selectedSeason = ""
    @State private var roster: [Player] = []
    @State private var games: [Game] = []
    @State private var record: [Game] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let dataManager = SimpleDataManager.shared
    private let cacheService = CacheService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Team Header
            TeamHeaderView(team: team)
                .padding()
            
            // Tab Picker
            Picker("Team Details", selection: $selectedTab) {
                Text("Roster").tag(0)
                Text("Games").tag(1)
                Text("Record").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Tab Content
            if selectedTab == 0 {
                RosterView(team: team, roster: $roster, isLoading: $isLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if selectedTab == 1 {
                GamesView(team: team, games: $games, selectedSeason: $selectedSeason, isLoading: $isLoading, errorMessage: $errorMessage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RecordView(team: team, selectedSeason: $selectedSeason, record: $record, isLoading: $isLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadTeamData()
        }
    }
    
    private func loadTeamData() async {
        isLoading = true
        errorMessage = nil
        
        // 1) Load games from cache first, filtered for team
        let cachedGamesAll = dataManager.fetchGames(for: team.league.id)
        let cachedTeamGames = cachedGamesAll.filter { $0.homeTeam.id == team.id || $0.awayTeam.id == team.id }
        let cachedCompleted = cachedTeamGames.filter { $0.isCompleted && $0.homeScore != nil && $0.awayScore != nil }
        await MainActor.run {
            self.games = cachedTeamGames.sorted { $0.gameTime < $1.gameTime }
            self.record = cachedCompleted.sorted { $0.gameTime < $1.gameTime }
        }
        
        // 2) Kick off cache refresh for league
        await cacheService.refreshDataIfNeeded(for: team.league.id)
        
        // 3) Fetch roster and latest games with retry; update cache and UI
        do {
            let roster = try await fetchTeamRosterWithRetry(teamId: team.id)
            let fetchedGames = try await fetchGamesWithRetry(leagueId: team.league.id)
            dataManager.saveGames(fetchedGames, for: team.league.id)
            
            let teamGames = dataManager.fetchGames(for: team.league.id).filter { $0.homeTeam.id == team.id || $0.awayTeam.id == team.id }
            let completedGames = teamGames.filter { $0.isCompleted && $0.homeScore != nil && $0.awayScore != nil }
            
            await MainActor.run {
                self.roster = roster
                self.games = teamGames.sorted { $0.gameTime < $1.gameTime }
                self.record = completedGames.sorted { $0.gameTime < $1.gameTime }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                if self.games.isEmpty { self.errorMessage = "Failed to load team data: \(error.localizedDescription)" }
                self.isLoading = false
            }
        }
    }

    private func fetchGamesWithRetry(leagueId: String, maxRetries: Int = 2) async throws -> [Game] {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                return try await YourServerAPI.shared.fetchGames(leagueId: leagueId)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
                }
            }
        }
        throw lastError ?? APIError.networkError("Unknown error")
    }
    
    private func fetchTeamRosterWithRetry(teamId: String, maxRetries: Int = 2) async throws -> [Player] {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                return try await YourServerAPI.shared.fetchTeamRoster(teamId: teamId)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
                }
            }
        }
        throw lastError ?? APIError.networkError("Unknown error")
    }
}

struct TeamHeaderView: View {
    let team: Team
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Team Logo
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "sportscourt.fill")
                            .font(.title)
                            .foregroundColor(.secondary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(team.league.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let conference = team.conference, let division = team.division {
                        Text("\(conference) \(division)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

struct RosterView: View {
    let team: Team
    @Binding var roster: [Player]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Roster List (current roster)
            if isLoading {
                ProgressView("Loading roster...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if roster.isEmpty {
                VStack {
                    Image(systemName: "person.3")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No roster data available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(roster) { player in
                            PlayerRow(player: player)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

struct PlayerRow: View {
    let player: Player
    
    var body: some View {
        NavigationLink(destination: AthleteMenuLoaderView(playerId: player.id)) {
            HStack {
                // Player Headshot
                AsyncImage(url: URL(string: player.photoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray4))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(player.positionString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let nationality = player.nationality {
                        Text(player.nationalityWithFlag)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if let jerseyNumber = player.jerseyNumber {
                        Text("#\(jerseyNumber)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    Text(player.heightString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Age: \(player.ageString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if player.isInjured {
                        Text(player.injuryStatus ?? "Injured")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // Navigation chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
}

struct GamesView: View {
    let team: Team
    @Binding var games: [Game]
    @Binding var selectedSeason: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    @State private var collapsedMonths: Set<String> = []
    
    private var seasons: [String] {
        let values = Array(Set(games.map { $0.season }))
        return values.sorted()
    }
    
    private func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy" // e.g., October 2025
        return formatter.string(from: date)
    }
    
    private var gamesByMonth: [String: [Game]] {
        let filtered = selectedSeason.isEmpty ? games : games.filter { $0.season == selectedSeason }
        var grouped: [String: [Game]] = [:]
        for game in filtered {
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
            // Header
            HStack {
                Text("Games")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if !seasons.isEmpty {
                    Picker("Season", selection: $selectedSeason) {
                        ForEach(seasons, id: \.self) { season in
                            Text(season).tag(season)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: seasons) { _, newSeasons in
                        // Ensure the selection is valid when seasons list changes
                        if !newSeasons.contains(selectedSeason) {
                            selectedSeason = newSeasons.last ?? ""
                        }
                    }
                }
            }
            
            if isLoading {
                ProgressView("Loading games...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error loading games")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if games.isEmpty {
                VStack {
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No games found")
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
                                    if collapsedMonths.contains(month) {
                                        collapsedMonths.remove(month)
                                    } else {
                                        collapsedMonths.insert(month)
                                    }
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
                                            GameCardTeam(game: game, viewingTeam: team)
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
        .onAppear {
            if selectedSeason.isEmpty, let last = seasons.last {
                selectedSeason = last
            }
        }
        .padding()
    }
}

struct RecordView: View {
    let team: Team
    @Binding var selectedSeason: String
    @Binding var record: [Game]
    @Binding var isLoading: Bool
    
    private var seasons: [String] {
        let values = Array(Set(record.map { $0.season }))
        return values.sorted()
    }
    
    private var filteredRecord: [Game] {
        selectedSeason.isEmpty ? record : record.filter { $0.season == selectedSeason }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Season Selector
            HStack {
                Text("Season:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Picker("Season", selection: $selectedSeason) {
                    ForEach(seasons, id: \.self) { season in
                        Text(season).tag(season)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: seasons) { _, newSeasons in
                    if !newSeasons.contains(selectedSeason) {
                        selectedSeason = newSeasons.last ?? ""
                    }
                }
                
                Spacer()
            }
            
            // Record Table
            if isLoading {
                ProgressView("Loading record...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredRecord.isEmpty {
                VStack {
                    Image(systemName: "chart.bar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No record data available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView([.horizontal, .vertical]) {
                        VStack(spacing: 0) {
                            // Header
                            HStack(spacing: 0) {
                                Text("DATE")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 60, alignment: .leading)
                                
                                Text("OPP")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 80, alignment: .leading)
                                
                                Text("SCORE")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 80)
                                
                                Text("W/L")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 40)
                                
                                Text("HI POINTS")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 100)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            
                            // Record Rows
                            ForEach(filteredRecord) { game in
                                RecordRowView(team: team, game: game)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if selectedSeason.isEmpty, let last = seasons.last {
                selectedSeason = last
            }
        }
        .padding()
    }
}

struct RecordRowView: View {
    let team: Team
    let game: Game
    
    private var opponent: Team {
        game.homeTeam.id == team.id ? game.awayTeam : game.homeTeam
    }
    
    private var teamScore: Int {
        game.homeTeam.id == team.id ? (game.homeScore ?? 0) : (game.awayScore ?? 0)
    }
    
    private var opponentScore: Int {
        game.homeTeam.id == team.id ? (game.awayScore ?? 0) : (game.homeScore ?? 0)
    }
    
    private var isWin: Bool {
        teamScore > opponentScore
    }
    
    private var gameDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: game.gameTime)
    }
    
    private var opponentDisplay: String {
        let isHome = game.homeTeam.id == team.id
        let prefix = isHome ? "vs" : "@"
        return "\(prefix) \(opponent.abbreviation ?? opponent.name)"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Date
            Text(gameDate)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            
            // Opponent (clickable)
            NavigationLink(destination: TeamMenuLoaderView(teamId: opponent.id)) {
                Text(opponentDisplay)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(width: 80, alignment: .leading)
            
            // Score
            Text("\(teamScore) - \(opponentScore)")
                .font(.subheadline)
                .frame(width: 80)
            
            // W/L indicator
            Text(isWin ? "W" : "L")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(isWin ? .green : .red)
                .frame(width: 40)
            
            // High points placeholder (would need player stats data)
            Text("TBD")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.clear)
        
        // Note: Divider will be handled by the parent ForEach
    }
}
