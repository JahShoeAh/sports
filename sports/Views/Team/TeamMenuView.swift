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
    @State private var selectedOpponentIds: Set<String> = []
    @State private var excludedOpponentIds: Set<String> = []
    @State private var showingOpponentFilter = false
    @State private var showingFilterPopup = false
    @State private var homeAwayFilter: HomeAwayFilter = .either
    @State private var winLossFilter: WinLossFilter = .either
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
                GamesView(
                    team: team,
                    games: $games,
                    selectedSeason: $selectedSeason,
                    selectedOpponentIds: $selectedOpponentIds,
                    excludedOpponentIds: $excludedOpponentIds,
                    showingOpponentFilter: $showingOpponentFilter,
                    showingFilterPopup: $showingFilterPopup,
                    homeAwayFilter: $homeAwayFilter,
                    winLossFilter: $winLossFilter,
                    isLoading: $isLoading,
                    errorMessage: $errorMessage
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RecordView(team: team, selectedSeason: $selectedSeason, record: $record, isLoading: $isLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            print("[TeamMenuView] onAppear for team \(team.id)")
            NavigationStateManager.shared.printCurrentState()
            
            // Always try to load persisted state, fall back to defaults if none exists
            print("[TeamMenuView] Loading state from NavigationStateManager")
            selectedTab = NavigationStateManager.shared.getTeamTab(teamId: team.id)
            selectedSeason = NavigationStateManager.shared.getTeamSeason(teamId: team.id)
            let opponentFilters = NavigationStateManager.shared.getTeamOpponentFilters(teamId: team.id)
            selectedOpponentIds = opponentFilters.selected
            excludedOpponentIds = opponentFilters.excluded
            homeAwayFilter = HomeAwayFilter(rawValue: NavigationStateManager.shared.getTeamHomeAwayFilter(teamId: team.id)) ?? .either
            winLossFilter = WinLossFilter(rawValue: NavigationStateManager.shared.getTeamWinLossFilter(teamId: team.id)) ?? .either
            print("[TeamMenuView] Loaded state - tab: \(selectedTab), season: '\(selectedSeason)', opponents: \(selectedOpponentIds.count) selected, \(excludedOpponentIds.count) excluded")
        }
        .onChange(of: selectedTab) { _, newTab in
            print("[TeamMenuView] Tab changed to \(newTab)")
            NavigationStateManager.shared.setTeamTab(teamId: team.id, tab: newTab)
        }
        .onChange(of: selectedSeason) { _, newSeason in
            print("[TeamMenuView] Season changed to '\(newSeason)'")
            NavigationStateManager.shared.setTeamSeason(teamId: team.id, season: newSeason)
        }
        .onChange(of: selectedOpponentIds) { _, newIds in
            print("[TeamMenuView] Selected opponents changed to \(newIds.count) items")
            NavigationStateManager.shared.setTeamOpponentFilters(teamId: team.id, selected: newIds, excluded: excludedOpponentIds)
        }
        .onChange(of: excludedOpponentIds) { _, newIds in
            print("[TeamMenuView] Excluded opponents changed to \(newIds.count) items")
            NavigationStateManager.shared.setTeamOpponentFilters(teamId: team.id, selected: selectedOpponentIds, excluded: newIds)
        }
        .onChange(of: homeAwayFilter) { _, newFilter in
            print("[TeamMenuView] Home/Away filter changed to \(newFilter.rawValue)")
            NavigationStateManager.shared.setTeamHomeAwayFilter(teamId: team.id, filter: newFilter.rawValue)
        }
        .onChange(of: winLossFilter) { _, newFilter in
            print("[TeamMenuView] Win/Loss filter changed to \(newFilter.rawValue)")
            NavigationStateManager.shared.setTeamWinLossFilter(teamId: team.id, filter: newFilter.rawValue)
        }
        .onDisappear {
            print("[TeamMenuView] onDisappear")
        }
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
                    
                    if player.nationality != nil {
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
    @Binding var selectedOpponentIds: Set<String>
    @Binding var excludedOpponentIds: Set<String>
    @Binding var showingOpponentFilter: Bool
    @Binding var showingFilterPopup: Bool
    @Binding var homeAwayFilter: HomeAwayFilter
    @Binding var winLossFilter: WinLossFilter
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    @State private var collapsedMonths: Set<String> = []
    
    private var seasons: [String] {
        let values = Array(Set(games.map { $0.season }))
        return values.sorted()
    }
    
    private var hasActiveFilters: Bool {
        !selectedOpponentIds.isEmpty || !excludedOpponentIds.isEmpty || homeAwayFilter != .either || winLossFilter != .either
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if !selectedOpponentIds.isEmpty || !excludedOpponentIds.isEmpty { count += 1 }
        if homeAwayFilter != .either { count += 1 }
        if winLossFilter != .either { count += 1 }
        return count
    }
    
    private func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy" // e.g., October 2025
        return formatter.string(from: date)
    }
    
    private var filteredGames: [Game] {
        var filtered = selectedSeason.isEmpty ? games : games.filter { $0.season == selectedSeason }
        
        // Apply opponent filtering
        if !selectedOpponentIds.isEmpty || !excludedOpponentIds.isEmpty {
            filtered = filtered.filter { game in
                let opponent = game.homeTeam.id == team.id ? game.awayTeam : game.homeTeam
                
                if !selectedOpponentIds.isEmpty {
                    // If opponents are selected, show only games with selected opponents (and exclude any excluded opponents)
                    let hasSelectedOpponent = selectedOpponentIds.contains(opponent.id)
                    let hasExcludedOpponent = excludedOpponentIds.contains(opponent.id)
                    return hasSelectedOpponent && !hasExcludedOpponent
                } else {
                    // If only opponents are excluded, filter out games where opponent is excluded
                    return !excludedOpponentIds.contains(opponent.id)
                }
            }
        }
        
        // Apply home/away filtering
        if homeAwayFilter != .either {
            filtered = filtered.filter { game in
                let isHome = game.homeTeam.id == team.id
                switch homeAwayFilter {
                case .home: return isHome
                case .away: return !isHome
                case .either: return true
                }
            }
        }
        
        // Apply win/loss filtering
        if winLossFilter != .either {
            filtered = filtered.filter { game in
                guard game.isCompleted, let homeScore = game.homeScore, let awayScore = game.awayScore else {
                    return false // Exclude incomplete games when filtering by win/loss
                }
                
                let isHome = game.homeTeam.id == team.id
                let teamScore = isHome ? homeScore : awayScore
                let opponentScore = isHome ? awayScore : homeScore
                let isWin = teamScore > opponentScore
                
                switch winLossFilter {
                case .wins: return isWin
                case .losses: return !isWin
                case .either: return true
                }
            }
        }
        
        return filtered
    }
    
    private var gamesByMonth: [String: [Game]] {
        var grouped: [String: [Game]] = [:]
        for game in filteredGames {
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
                
                Spacer()
                
                Button(action: {
                    showingFilterPopup.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showingFilterPopup ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(.blue)
                        if hasActiveFilters {
                            Text("\(activeFilterCount)")
                                .font(.caption)
                                .foregroundColor(.blue)
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
            } else if filteredGames.isEmpty {
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
        .sheet(isPresented: $showingOpponentFilter) {
            OpponentFilterSheet(
                team: team,
                games: games,
                selectedOpponentIds: $selectedOpponentIds,
                excludedOpponentIds: $excludedOpponentIds,
                isPresented: $showingOpponentFilter
            )
        }
        .overlay(
            // Filter Options Popup
            Group {
                if showingFilterPopup {
                    VStack {
                        HStack {
                            Spacer()
                            
                            FilterOptionsPopup(
                                team: team,
                                selectedOpponentIds: $selectedOpponentIds,
                                excludedOpponentIds: $excludedOpponentIds,
                                showingOpponentFilter: $showingOpponentFilter,
                                showingFilterPopup: $showingFilterPopup,
                                homeAwayFilter: $homeAwayFilter,
                                winLossFilter: $winLossFilter
                            )
                            .frame(width: 200)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .offset(y: 60) // Position close to the filter button
                            .padding(.trailing, 16) // Align right edge close to filter button
                        }
                        
                        Spacer()
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingFilterPopup)
                }
            }
        )
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
            NavigationLink(destination: GameMenuView(game: game)) {
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

// MARK: - Opponent Filter Sheet
struct OpponentFilterSheet: View {
    let team: Team
    let games: [Game]
    @Binding var selectedOpponentIds: Set<String>
    @Binding var excludedOpponentIds: Set<String>
    @Binding var isPresented: Bool
    
    private var opponentTeams: [Team] {
        // Get all unique opponents from games, excluding the current team
        let opponents = games.compactMap { game -> Team? in
            if game.homeTeam.id == team.id {
                return game.awayTeam
            } else if game.awayTeam.id == team.id {
                return game.homeTeam
            }
            return nil
        }
        
        // Remove duplicates and sort by name
        let uniqueOpponents = Array(Set(opponents.map { $0.id }))
            .compactMap { id in opponents.first { $0.id == id } }
            .sorted { $0.name < $1.name }
        
        return uniqueOpponents
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clear Filters Button
                Button(action: {
                    selectedOpponentIds.removeAll()
                    excludedOpponentIds.removeAll()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Clear Filters")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
                .disabled(selectedOpponentIds.isEmpty && excludedOpponentIds.isEmpty)
                
                Divider()
                
                // Opponents List
                List {
                    ForEach(opponentTeams) { opponent in
                        OpponentFilterRow(
                            opponent: opponent,
                            selectedOpponentIds: $selectedOpponentIds,
                            excludedOpponentIds: $excludedOpponentIds
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Filter by Opponent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Opponent Filter Row
struct OpponentFilterRow: View {
    let opponent: Team
    @Binding var selectedOpponentIds: Set<String>
    @Binding var excludedOpponentIds: Set<String>
    
    private var opponentState: TeamFilterState {
        if selectedOpponentIds.contains(opponent.id) {
            return .selected
        } else if excludedOpponentIds.contains(opponent.id) {
            return .excluded
        } else {
            return .unselected
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Opponent Logo
            AsyncImage(url: URL(string: opponent.logoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "person.3")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 40, height: 40)
            
            // Opponent Info
            VStack(alignment: .leading, spacing: 2) {
                Text(opponent.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(opponent.city)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // State Indicator
            switch opponentState {
            case .selected:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            case .excluded:
                Image(systemName: "circle.slash")
                    .foregroundColor(.red)
                    .font(.title2)
            case .unselected:
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            cycleOpponentState()
        }
    }
    
    private func cycleOpponentState() {
        switch opponentState {
        case .unselected:
            // Add to selected, remove from excluded
            selectedOpponentIds.insert(opponent.id)
            excludedOpponentIds.remove(opponent.id)
        case .selected:
            // Remove from selected, add to excluded
            selectedOpponentIds.remove(opponent.id)
            excludedOpponentIds.insert(opponent.id)
        case .excluded:
            // Remove from excluded, back to unselected
            excludedOpponentIds.remove(opponent.id)
        }
    }
}

// MARK: - Filter Options Popup
struct FilterOptionsPopup: View {
    let team: Team
    @Binding var selectedOpponentIds: Set<String>
    @Binding var excludedOpponentIds: Set<String>
    @Binding var showingOpponentFilter: Bool
    @Binding var showingFilterPopup: Bool
    @Binding var homeAwayFilter: HomeAwayFilter
    @Binding var winLossFilter: WinLossFilter
    
    var body: some View {
        VStack(spacing: 0) {
            // Opponent Filter Option
            Button(action: {
                showingOpponentFilter = true
                showingFilterPopup = false
            }) {
                HStack {
                    Text("By opponent")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !selectedOpponentIds.isEmpty || !excludedOpponentIds.isEmpty {
                        Text("\(selectedOpponentIds.count + excludedOpponentIds.count)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            // Home/Away Filter Option
            Button(action: {
                homeAwayFilter = homeAwayFilter.next
            }) {
                HStack {
                    Text(homeAwayFilter.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            // Win/Loss Filter Option
            Button(action: {
                winLossFilter = winLossFilter.next
            }) {
                HStack {
                    Text(winLossFilter.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Filter Enums
enum HomeAwayFilter: String, CaseIterable {
    case either = "Home or away: either"
    case home = "Home only"
    case away = "Away only"
    
    var next: HomeAwayFilter {
        switch self {
        case .either: return .home
        case .home: return .away
        case .away: return .either
        }
    }
}

enum WinLossFilter: String, CaseIterable {
    case either = "Win or loss: either"
    case wins = "Wins only"
    case losses = "Losses only"
    
    var next: WinLossFilter {
        switch self {
        case .either: return .wins
        case .wins: return .losses
        case .losses: return .either
        }
    }
}
