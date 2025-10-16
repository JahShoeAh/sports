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
    @State private var selectedSeason = "2025"
    @State private var roster: [Player] = []
    @State private var games: [Game] = []
    @State private var record: [Game] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Team Header
                TeamHeaderView(team: team)
                
                // Tab View
                VStack(spacing: 0) {
                    // Tab Picker
                    Picker("Team Details", selection: $selectedTab) {
                        Text("Roster").tag(0)
                        Text("Games").tag(1)
                        Text("Record").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        RosterView(team: team, selectedSeason: $selectedSeason, roster: $roster, isLoading: $isLoading)
                            .tag(0)
                        
                        GamesView(team: team, games: $games, isLoading: $isLoading, errorMessage: $errorMessage)
                            .tag(1)
                        
                        RecordView(team: team, selectedSeason: $selectedSeason, record: $record, isLoading: $isLoading)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 400)
                }
            }
            .padding()
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
        
        do {
            // Load roster from API
            let fetchedRoster = try await YourServerAPI.shared.fetchTeamRoster(teamId: team.id)
            
            // Load games for this team's league
            let teamGames = try await YourServerAPI.shared.fetchGames(leagueId: team.league.id)
            let filteredGames = teamGames.filter { game in
                game.homeTeam.id == team.id || game.awayTeam.id == team.id
            }
            
            // Filter completed games for record
            let completedGames = filteredGames.filter { $0.isCompleted && $0.homeScore != nil && $0.awayScore != nil }
            
            await MainActor.run {
                self.roster = fetchedRoster
                self.games = filteredGames.sorted { $0.gameTime > $1.gameTime }
                self.record = completedGames.sorted { $0.gameTime > $1.gameTime }
                self.isLoading = false
            }
        } catch {
            print("Error loading team data: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load team data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
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
    @Binding var selectedSeason: String
    @Binding var roster: [Player]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Season Selector
            HStack {
                Text("Season:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Picker("Season", selection: $selectedSeason) {
                    Text("2025 Regular").tag("2025")
                    Text("2025 Postseason").tag("2025-post")
                    Text("2024 Regular").tag("2024")
                    Text("2024 Postseason").tag("2024-post")
                    Text("2023 Regular").tag("2023")
                    Text("2023 Postseason").tag("2023-post")
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            
            // Roster List
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
        .padding()
    }
}

struct PlayerRow: View {
    let player: Player
    
    var body: some View {
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
        }
        .padding(.vertical, 4)
    }
}

struct GamesView: View {
    let team: Team
    @Binding var games: [Game]
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Games")
                .font(.headline)
                .fontWeight(.semibold)
            
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
                // Use the existing GameScheduleView component
                GameScheduleView(
                    games: games,
                    isLoading: false,
                    errorMessage: nil,
                    onGameTap: { _ in }
                )
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Season Selector
            HStack {
                Text("Season:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Picker("Season", selection: $selectedSeason) {
                    Text("2025 Regular").tag("2025")
                    Text("2025 Postseason").tag("2025-post")
                    Text("2024 Regular").tag("2024")
                    Text("2024 Postseason").tag("2024-post")
                    Text("2023 Regular").tag("2023")
                    Text("2023 Postseason").tag("2023-post")
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            
            // Record Table
            if isLoading {
                ProgressView("Loading record...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if record.isEmpty {
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
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Opponent")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Score")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 80)
                            
                            Text("W/L")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 40)
                            
                            Text("Top Scorer")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 100)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        
                        // Record Rows
                        ForEach(record) { game in
                            RecordRowView(team: team, game: game)
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
    
    var body: some View {
        HStack {
            // Opponent name (clickable)
            NavigationLink(destination: TeamMenuView(team: opponent)) {
                Text(opponent.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
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
            
            // Top scorer placeholder (would need player stats data)
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
