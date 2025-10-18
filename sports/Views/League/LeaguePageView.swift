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
    @State private var selectedSeason: String = ""
    @State private var games: [Game] = []
    @State private var teams: [Team] = []
    @State private var availableSeasons: [String] = []
    @State private var seasonsLoaded: Bool = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingTeamFilter: Bool = false
    @State private var selectedTeamIds: Set<String> = []
    @State private var excludedTeamIds: Set<String> = []
    
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
            
            // Season Selector and Controls (only show on schedule tab)
            if selectedTab == .schedule {
                VStack(spacing: 8) {
                    // Top row: Season picker and filter button
                    HStack {
                        Group {
                            if seasonsLoaded && !availableSeasons.isEmpty {
                                Picker("Season", selection: $selectedSeason) {
                                    ForEach(availableSeasons, id: \.self) { season in
                                        Text(season).tag(season)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .lineLimit(1)
                            } else if seasonsLoaded && availableSeasons.isEmpty {
                                Text("No seasons available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                    Text("Loading seasons...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: selectedSeason) { oldValue, newValue in
                            print("Season changed from \(oldValue) to \(newValue)")
                            if oldValue != newValue {
                                loadGames(season: newValue)
                            }
                        }
                        .onChange(of: availableSeasons) { _, newSeasons in
                            // Ensure the selectedSeason always has a valid tag
                            if !newSeasons.contains(selectedSeason) {
                                selectedSeason = newSeasons.last ?? ""
                            }
                        }
                        
                        Spacer()
                        
                        // Filter Button
                        Button(action: {
                            showingTeamFilter = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundColor(.blue)
                                if !selectedTeamIds.isEmpty || !excludedTeamIds.isEmpty {
                                    Text("\(selectedTeamIds.count + excludedTeamIds.count)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .disabled(teams.isEmpty)
                    }
                    
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
            }
            
            Divider()
            
            // Content
            Group {
                switch selectedTab {
                case .schedule:
                    GameScheduleView(
                        allGames: games,
                        teams: teams,
                        selectedTeamIds: selectedTeamIds,
                        excludedTeamIds: excludedTeamIds,
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
        .onAppear {
            print("[LeaguePageView] onAppear for league \(league.id)")
            
            // Always try to load persisted state, fall back to defaults if none exists
            print("[LeaguePageView] Loading state from NavigationStateManager")
            let savedTab = NavigationStateManager.shared.getLeagueTab(leagueId: league.id)
            selectedTab = LeagueTab(rawValue: savedTab) ?? .schedule
            selectedSeason = NavigationStateManager.shared.getLeagueSeason(leagueId: league.id)
            let teamFilters = NavigationStateManager.shared.getLeagueTeamFilters(leagueId: league.id)
            selectedTeamIds = teamFilters.selected
            excludedTeamIds = teamFilters.excluded
            print("[LeaguePageView] Loaded state - tab: \(selectedTab.rawValue), season: '\(selectedSeason)', teams: \(selectedTeamIds.count) selected, \(excludedTeamIds.count) excluded")
        }
        .onChange(of: selectedTab) { _, newTab in
            print("[LeaguePageView] Tab changed to \(newTab.rawValue)")
            NavigationStateManager.shared.setLeagueTab(leagueId: league.id, tab: newTab.rawValue)
        }
        .onChange(of: selectedSeason) { _, newSeason in
            print("[LeaguePageView] Season changed to '\(newSeason)'")
            NavigationStateManager.shared.setLeagueSeason(leagueId: league.id, season: newSeason)
        }
        .onChange(of: selectedTeamIds) { _, newIds in
            print("[LeaguePageView] Selected teams changed to \(newIds.count) items")
            NavigationStateManager.shared.setLeagueTeamFilters(leagueId: league.id, selected: newIds, excluded: excludedTeamIds)
        }
        .onChange(of: excludedTeamIds) { _, newIds in
            print("[LeaguePageView] Excluded teams changed to \(newIds.count) items")
            NavigationStateManager.shared.setLeagueTeamFilters(leagueId: league.id, selected: selectedTeamIds, excluded: newIds)
        }
        .task {
            await loadInitialData()
        }
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showingTeamFilter) {
            TeamFilterSheet(
                teams: teams,
                selectedTeamIds: $selectedTeamIds,
                excludedTeamIds: $excludedTeamIds,
                isPresented: $showingTeamFilter
            )
        }
        .onDisappear {
            print("[LeaguePageView] onDisappear")
        }
    }
    
    private func loadInitialData() async {
        // First, try to load from cache
        loadCachedData()
        
        // Load seasons efficiently - try cache first, then server if needed
        await loadSeasonsEfficiently()
        
        // Then check if we need to refresh data
        await cacheService.refreshDataIfNeeded(for: league.id)
        
        // Reload from cache after potential refresh
        loadCachedData()
    }

    private func loadSeasonsEfficiently() async {
        // First, try to derive seasons from cached games
        let cachedGames = dataManager.fetchGames(for: league.id, season: nil)
        let cachedSeasons = Array(Set(cachedGames.map { $0.season })).sorted()
        
        await MainActor.run {
            if !cachedSeasons.isEmpty {
                self.availableSeasons = cachedSeasons
                self.seasonsLoaded = true
                print("[LeaguePage] Seasons loaded from cache: \(cachedSeasons)")
                
                // Set default season if needed
                if self.selectedSeason.isEmpty || !cachedSeasons.contains(self.selectedSeason) {
                    self.selectedSeason = cachedSeasons.last ?? ""
                    print("[LeaguePage] Defaulting selectedSeason to: \(self.selectedSeason)")
                    if !self.selectedSeason.isEmpty {
                        self.loadGames(season: self.selectedSeason)
                    }
                }
            }
        }
        
        // If we have seasons from cache, we're done
        if !cachedSeasons.isEmpty {
            return
        }
        
        // If no cached seasons, try to fetch from server
        do {
            print("[LeaguePage] No cached seasons, fetching from server for league: \(league.id)")
            let seasons = try await yourServerAPI.fetchSeasons(leagueId: league.id)
            await MainActor.run {
                self.availableSeasons = seasons
                self.seasonsLoaded = true
                print("[LeaguePage] Seasons loaded from server: \(seasons)")
                if self.selectedSeason.isEmpty || !seasons.contains(self.selectedSeason) {
                    self.selectedSeason = seasons.last ?? ""
                    print("[LeaguePage] Defaulting selectedSeason to: \(self.selectedSeason)")
                    if !self.selectedSeason.isEmpty {
                        self.loadGames(season: self.selectedSeason)
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.seasonsLoaded = true
                print("[LeaguePage] Failed to fetch seasons from server: \(error)")
                // Keep empty seasons array, picker will show loading state
            }
        }
    }
    
    private func loadCachedData() {
        // Load games from cache
        games = dataManager.fetchGames(for: league.id, season: selectedSeason)
        
        // Only recompute seasons if we don't have any yet (seasonsLoaded is false)
        if !seasonsLoaded {
            let allLeagueGames = dataManager.fetchGames(for: league.id, season: nil)
            availableSeasons = Array(Set(allLeagueGames.map { $0.season })).sorted()
            if selectedSeason.isEmpty || !availableSeasons.contains(selectedSeason) {
                selectedSeason = availableSeasons.last ?? ""
            }
        }
        
        // Load teams from cache
        teams = dataManager.fetchTeams(for: league.id)
        
        // Clear any previous errors
        errorMessage = nil
    }
    
    private func loadGames(season: String) {
        print("Loading games for season: \(season)")
        
        // Load games from cache for the selected season
        games = dataManager.fetchGames(for: league.id, season: season)
        print("Found \(games.count) games in cache for season \(season)")
        
        // Always try to fetch from server to ensure we have the latest data for this season
        Task {
            await fetchGamesFromServer(season: season)
        }
    }
    
    private func fetchGamesFromServer(season: String) async {
        print("Fetching games from server for season: \(season)")
        do {
            let fetchedGames = try await yourServerAPI.fetchGames(leagueId: league.id, season: season)
            print("Successfully fetched \(fetchedGames.count) games from server for season \(season)")
            dataManager.saveGames(fetchedGames, for: league.id)
            
            await MainActor.run {
                games = dataManager.fetchGames(for: league.id, season: season)
                print("Updated games array with \(games.count) games for season \(season)")
                // Refresh available seasons again in case new seasons appeared
                let allLeagueGames = dataManager.fetchGames(for: league.id, season: nil)
                let newSeasons = Array(Set(allLeagueGames.map { $0.season })).sorted()
                if newSeasons != availableSeasons {
                    availableSeasons = newSeasons
                    print("[LeaguePage] Updated available seasons: \(newSeasons)")
                    if !availableSeasons.contains(selectedSeason) {
                        selectedSeason = availableSeasons.last ?? selectedSeason
                    }
                }
            }
        } catch {
            print("Error fetching games from server: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load games: \(error.localizedDescription)"
            }
        }
    }
    
    private func refreshData() async {
        errorMessage = nil
        
        // Reset seasons loading state
        await MainActor.run {
            seasonsLoaded = false
            availableSeasons = []
        }
        
        // Clear cache and force refresh
        dataManager.clearData(for: league.id)
        
        // Load seasons efficiently (will try cache first, then server)
        await loadSeasonsEfficiently()
        
        // Fetch fresh data from server for current season
        if !selectedSeason.isEmpty {
            await fetchGamesFromServer(season: selectedSeason)
        }
        
        // Also fetch teams
        do {
            let teams = try await yourServerAPI.fetchTeams(leagueId: league.id)
            dataManager.saveTeams(teams, for: league.id)
        } catch {
            print("Error fetching teams: \(error)")
        }
        
        await MainActor.run {
            loadCachedData()
        }
    }
    
}

// MARK: - Team Filter Sheet
struct TeamFilterSheet: View {
    let teams: [Team]
    @Binding var selectedTeamIds: Set<String>
    @Binding var excludedTeamIds: Set<String>
    @Binding var isPresented: Bool
    
    private var sortedTeams: [Team] {
        teams.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clear Filters Button
                Button(action: {
                    selectedTeamIds.removeAll()
                    excludedTeamIds.removeAll()
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
                .disabled(selectedTeamIds.isEmpty && excludedTeamIds.isEmpty)
                
                Divider()
                
                // Teams List
                List {
                    ForEach(sortedTeams) { team in
                        TeamFilterRow(
                            team: team,
                            selectedTeamIds: $selectedTeamIds,
                            excludedTeamIds: $excludedTeamIds
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Filter by Team")
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

// MARK: - Team Filter Row
struct TeamFilterRow: View {
    let team: Team
    @Binding var selectedTeamIds: Set<String>
    @Binding var excludedTeamIds: Set<String>
    
    private var teamState: TeamFilterState {
        if selectedTeamIds.contains(team.id) {
            return .selected
        } else if excludedTeamIds.contains(team.id) {
            return .excluded
        } else {
            return .unselected
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Team Logo
            AsyncImage(url: URL(string: team.logoURL ?? "")) { image in
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
            
            // Team Info
            VStack(alignment: .leading, spacing: 2) {
                Text(team.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(team.city)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // State Indicator
            switch teamState {
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
            cycleTeamState()
        }
    }
    
    private func cycleTeamState() {
        switch teamState {
        case .unselected:
            // Add to selected, remove from excluded
            selectedTeamIds.insert(team.id)
            excludedTeamIds.remove(team.id)
        case .selected:
            // Remove from selected, add to excluded
            selectedTeamIds.remove(team.id)
            excludedTeamIds.insert(team.id)
        case .excluded:
            // Remove from excluded, back to unselected
            excludedTeamIds.remove(team.id)
        }
    }
}

// MARK: - Team Filter State
enum TeamFilterState {
    case unselected
    case selected
    case excluded
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
