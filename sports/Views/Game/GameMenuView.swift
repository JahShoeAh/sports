//
//  GameMenuView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct GameMenuView: View {
    let game: Game
    @State private var selectedTab = 0
    @State private var hasUserLogged = false
    @State private var showingLogGame = false
    @State private var showingReviews = false
    @State private var isInWatchlist = false
    
    // Check if game has started (short-circuit evaluation)
    var hasGameStarted: Bool {
        game.isCompleted || Date() > game.gameTime
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Game Header
                GameHeaderView(game: game)
                
                // To Watch Button
                ToWatchButton(isInWatchlist: $isInWatchlist, gameId: game.id)
                
                // Conditional Content (only if game has started)
                if hasGameStarted {
                    // Rating Distribution
                    RatingDistributionView()
                    
                    // What they're saying button
                    WhatTheyreSayingButton(showingReviews: $showingReviews)
                    
                    // Log, rate, review, tag button
                    LogGameButton(hasUserLogged: hasUserLogged, showingLogGame: $showingLogGame)
                    
                    // Tab View
                    GameDetailsTabView(game: game, selectedTab: $selectedTab)
                }
            }
            .padding()
        }
        .navigationTitle(game.displayTitle)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingLogGame) {
            LogGameView(game: game)
        }
        .sheet(isPresented: $showingReviews) {
            GameReviewsView(game: game)
        }
    }
}

struct GameHeaderView: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title: "Away Team vs. Home Team" with clickable team names
            HStack(spacing: 8) {
                NavigationLink(destination: TeamMenuView(team: game.awayTeam)) {
                    Text(game.awayTeam.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text("vs.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                NavigationLink(destination: TeamMenuView(team: game.homeTeam)) {
                    Text(game.homeTeam.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(game.gameTime, style: .date)
                    .foregroundColor(.secondary)
            }
            
            // Start Time
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text(game.gameTime, style: .time)
                    .foregroundColor(.secondary)
            }
            
            // Venue name and city
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                if let venue = game.venue {
                    Text(venue.fullLocation)
                        .foregroundColor(.secondary)
                } else {
                    Text("Venue TBD")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct ToWatchButton: View {
    @Binding var isInWatchlist: Bool
    let gameId: String
    
    var body: some View {
        Button(action: {
            print("add \(gameId) to watchlist")
            isInWatchlist.toggle()
        }) {
            HStack {
                Image(systemName: isInWatchlist ? "bookmark.fill" : "bookmark")
                Text("To Watch")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct WhatTheyreSayingButton: View {
    @Binding var showingReviews: Bool
    
    var body: some View {
        Button(action: {
            print("Clicked: What they're saying. From page: Game Menu. Actions performed: showingReviews = true. TODO: Show reviews sheet")
            showingReviews = true
        }) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                Text("What they're saying")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct LogGameButton: View {
    let hasUserLogged: Bool
    @Binding var showingLogGame: Bool
    
    var body: some View {
        Button(action: {
            print("Clicked: \(hasUserLogged ? "Log Again" : "Log, rate, review, tag..."). From page: Game Menu. Actions performed: showingLogGame = true. TODO: Show log game sheet")
            showingLogGame = true
        }) {
            HStack {
                Image(systemName: "star")
                Text(hasUserLogged ? "Log Again" : "Log, rate, review, tag...")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

struct LiveBanner: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            Text("LIVE NOW")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}


struct RatingDistributionView: View {
    // Mock data for rating distribution
    let ratingData = [1: 2, 2: 1, 3: 3, 4: 5, 5: 8, 6: 12, 7: 15, 8: 18, 9: 10, 10: 6]
    
    var maxCount: Int {
        ratingData.values.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Entertainment Rating Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Vertical bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(1...10, id: \.self) { rating in
                    VStack(spacing: 4) {
                        // Bar
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 20, height: CGFloat(ratingData[rating] ?? 0) / CGFloat(maxCount) * 100)
                            .cornerRadius(2)
                        
                        // Rating number
                        Text("\(rating)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 120)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct GameDetailsTabView: View {
    let game: Game
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Details", selection: $selectedTab) {
                Text("Results").tag(0)
                Text("Home Box Score").tag(1)
                Text("Away Box Score").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Tab Content
            TabView(selection: $selectedTab) {
                GameResultView(game: game)
                    .tag(0)
                
                BoxScoreView(team: game.homeTeam, isHome: true, game: game)
                    .tag(1)
                
                BoxScoreView(team: game.awayTeam, isHome: false, game: game)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
        }
    }
}


struct GameResultView: View {
    let game: Game
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Game Result")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // Line Score Table
                if let homeLineScore = game.homeLineScore, let awayLineScore = game.awayLineScore {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Team")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(0..<homeLineScore.count, id: \.self) { quarter in
                                Text("Q\(quarter + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 40)
                            }
                            
                            Text("Total")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 50)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        
                        // Away Team
                        HStack {
                            NavigationLink(destination: TeamMenuView(team: game.awayTeam)) {
                                Text(game.awayTeam.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(0..<awayLineScore.count, id: \.self) { quarter in
                                Text("\(awayLineScore[quarter])")
                                    .font(.subheadline)
                                    .frame(width: 40)
                            }
                            
                            Text("\(awayLineScore.reduce(0, +))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 50)
                        }
                        .padding(.vertical, 8)
                        
                        // Home Team
                        HStack {
                            NavigationLink(destination: TeamMenuView(team: game.homeTeam)) {
                                Text(game.homeTeam.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(0..<homeLineScore.count, id: \.self) { quarter in
                                Text("\(homeLineScore[quarter])")
                                    .font(.subheadline)
                                    .frame(width: 40)
                            }
                            
                            Text("\(homeLineScore.reduce(0, +))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 50)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                } else {
                    Text("Line scores not available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct BoxScoreView: View {
    let team: Team
    let isHome: Bool
    let game: Game
    
    @StateObject private var api = YourServerAPI.shared
    @State private var playerStats: [PlayerStats] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink(destination: TeamMenuView(team: team)) {
                    Text("\(team.name) Box Score")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                if isLoading {
                    ProgressView("Loading box score...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else if playerStats.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No box score data available for this game")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else {
                    // Box Score Table
                    BoxScoreTableView(playerStats: playerStats)
                }
            }
        }
        .task {
            await loadBoxScore()
        }
    }
    
    private func loadBoxScore() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch player stats for this specific game and team
            let stats = try await api.fetchPlayerStats(gameId: game.id, teamId: team.id)
            playerStats = stats
        } catch {
            errorMessage = "Failed to load box score: \(error.localizedDescription)"
            playerStats = []
        }
        
        isLoading = false
    }
}

struct BoxScoreTableView: View {
    let playerStats: [PlayerStats]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Player")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("MIN")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 40)
                
                Text("PTS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 30)
                
                Text("REB")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 30)
                
                Text("AST")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 30)
                
                Text("STL")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 30)
                
                Text("BLK")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(width: 30)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Player Rows
            ForEach(playerStats) { stat in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.player.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if let jerseyNumber = stat.player.jerseyNumber {
                            Text("#\(jerseyNumber)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(stat.min)
                        .font(.caption)
                        .frame(width: 40)
                    
                    Text("\(stat.points)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 30)
                    
                    Text("\(stat.totReb)")
                        .font(.caption)
                        .frame(width: 30)
                    
                    Text("\(stat.assists)")
                        .font(.caption)
                        .frame(width: 30)
                    
                    Text("\(stat.steals)")
                        .font(.caption)
                        .frame(width: 30)
                    
                    Text("\(stat.blocks)")
                        .font(.caption)
                        .frame(width: 30)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.clear)
                
                if stat.id != playerStats.last?.id {
                    Divider()
                        .padding(.horizontal, 12)
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
