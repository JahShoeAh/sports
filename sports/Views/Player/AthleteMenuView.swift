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
    @State private var selectedSeason = "2025"
    @State private var selectedTeam: Team?
    @State private var pastGames: [Game] = []
    @State private var stats: [String: Any] = [:]
    @State private var isLoading = false
    
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
                        
                        PlayerStatsView(player: player, selectedSeason: $selectedSeason, selectedTeam: $selectedTeam, stats: $stats, isLoading: $isLoading)
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
    }
    
    private func loadPlayerData() async {
        isLoading = true
        
        // TODO: Load past games and stats from API
        await MainActor.run {
            self.isLoading = false
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
                        Text("Age: \(player.age)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Height: \(player.heightFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Weight: \(player.weightLbs) lbs")
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

struct PlayerStatsView: View {
    let player: Player
    @Binding var selectedSeason: String
    @Binding var selectedTeam: Team?
    @Binding var stats: [String: Any]
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
                        Text("2025").tag("2025")
                        Text("2024").tag("2024")
                        Text("2023").tag("2023")
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Spacer()
                }
                
                if let selectedTeam = selectedTeam {
                    HStack {
                        Text("Team:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(selectedTeam.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            
            // Stats Table
            if isLoading {
                ProgressView("Loading stats...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if stats.isEmpty {
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
                ScrollView {
                    VStack(spacing: 0) {
                        // TODO: Implement stats table based on sport and position
                        VStack {
                            Text("Stats table will be displayed here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
        }
        .padding()
    }
}
