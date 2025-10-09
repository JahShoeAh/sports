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
    @State private var pastGames: [Game] = []
    @State private var futureGames: [Game] = []
    @State private var isLoading = false
    
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
                        Text("Past Games").tag(1)
                        Text("Future Schedule").tag(2)
                        Text("Record").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        RosterView(team: team, selectedSeason: $selectedSeason, roster: $roster, isLoading: $isLoading)
                            .tag(0)
                        
                        PastGamesView(team: team, pastGames: $pastGames, isLoading: $isLoading)
                            .tag(1)
                        
                        FutureScheduleView(team: team, futureGames: $futureGames, isLoading: $isLoading)
                            .tag(2)
                        
                        RecordView(team: team, selectedSeason: $selectedSeason)
                            .tag(3)
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
        
        // TODO: Load roster, past games, future games from API
        await MainActor.run {
            self.isLoading = false
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
                    Text("2025").tag("2025")
                    Text("2024").tag("2024")
                    Text("2023").tag("2023")
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
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(player.position)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let jerseyNumber = player.jerseyNumber {
                    Text("#\(jerseyNumber)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                if let height = player.height {
                    Text(height)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let age = player.age {
                    Text("Age: \(age)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PastGamesView: View {
    let team: Team
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(pastGames) { game in
                            GamePosterCard(game: game)
                                .frame(height: 200)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct FutureScheduleView: View {
    let team: Team
    @Binding var futureGames: [Game]
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Future Schedule")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isLoading {
                ProgressView("Loading future games...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if futureGames.isEmpty {
                VStack {
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No future games scheduled")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(futureGames) { game in
                            GamePosterCard(game: game)
                                .frame(height: 200)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct RecordView: View {
    let team: Team
    @Binding var selectedSeason: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Season Selector
            HStack {
                Text("Season:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Picker("Season", selection: $selectedSeason) {
                    Text("2025").tag("2025")
                    Text("2024").tag("2024")
                    Text("2023").tag("2023")
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            
            // Record Table
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Opponent")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Score")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("W/L")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 40)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // TODO: Implement record rows
                VStack {
                    Text("Record data will be displayed here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        TeamMenuView(team: Team(
            id: "1",
            name: "Chiefs",
            city: "Kansas City",
            abbreviation: "KC",
            logoURL: nil,
            league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, isActive: true),
            conference: "AFC",
            division: "West",
            colors: nil
        ))
    }
}
