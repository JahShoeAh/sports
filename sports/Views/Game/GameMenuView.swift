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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Game Header
                GameHeaderView(game: game)
                
                // Live Banner
                if game.isLive {
                    LiveBanner()
                }
                
                // Action Buttons
                ActionButtonsView(
                    hasUserLogged: hasUserLogged,
                    isInWatchlist: isInWatchlist,
                    showingLogGame: $showingLogGame,
                    showingReviews: $showingReviews
                )
                
                // Poll Section
                PollSectionView(game: game)
                
                // Rating Distribution (if game is completed)
                if game.isCompleted {
                    RatingDistributionView()
                }
                
                // Tab View
                GameDetailsTabView(game: game, selectedTab: $selectedTab)
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
            Text(game.displayTitle)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(game.gameDate, style: .date)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text(game.gameTime, style: .time)
                    .foregroundColor(.secondary)
            }
            
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
            
            if let homeScore = game.homeScore, let awayScore = game.awayScore {
                HStack {
                    Text("Final Score:")
                        .fontWeight(.medium)
                    Text("\(game.awayTeam.name) \(awayScore) - \(homeScore) \(game.homeTeam.name)")
                        .fontWeight(.bold)
                }
                .padding(.top, 8)
            }
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

struct ActionButtonsView: View {
    let hasUserLogged: Bool
    let isInWatchlist: Bool
    @Binding var showingLogGame: Bool
    @Binding var showingReviews: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    print("Clicked: To Watch. From page: Game Menu. Actions performed: none. TODO: Toggle watchlist")
                    // TODO: Toggle watchlist
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
}

struct PollSectionView: View {
    let game: Game
    @State private var selectedOption: String?
    @State private var hasVoted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Predict the winner")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                PollOptionButton(
                    team: game.awayTeam,
                    isSelected: selectedOption == game.awayTeam.id,
                    isEnabled: !hasVoted && !game.isCompleted
                ) {
                    print("Clicked: \(game.awayTeam.name) (Poll). From page: Game Menu. Actions performed: selectedOption = \(game.awayTeam.id). TODO: Submit vote")
                    selectedOption = game.awayTeam.id
                    // TODO: Submit vote
                }
                
                PollOptionButton(
                    team: game.homeTeam,
                    isSelected: selectedOption == game.homeTeam.id,
                    isEnabled: !hasVoted && !game.isCompleted
                ) {
                    print("Clicked: \(game.homeTeam.name) (Poll). From page: Game Menu. Actions performed: selectedOption = \(game.homeTeam.id). TODO: Submit vote")
                    selectedOption = game.homeTeam.id
                    // TODO: Submit vote
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PollOptionButton: View {
    let team: Team
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(team.name)
                    .fontWeight(.medium)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray5))
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

struct RatingDistributionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Entertainment Rating Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            // TODO: Implement rating distribution chart
            Text("Rating distribution chart will be implemented here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
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
                Text("Starting").tag(0)
                Text("Result").tag(1)
                Text("Home Box Score").tag(2)
                Text("Away Box Score").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Tab Content
            TabView(selection: $selectedTab) {
                StartingLineupView(game: game)
                    .tag(0)
                
                GameResultView(game: game)
                    .tag(1)
                
                BoxScoreView(team: game.homeTeam, isHome: true)
                    .tag(2)
                
                BoxScoreView(team: game.awayTeam, isHome: false)
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
        }
    }
}

struct StartingLineupView: View {
    let game: Game
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Starting Lineups")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // TODO: Implement starting lineups
                Text("Starting lineups will be displayed here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
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
                
                // TODO: Implement game result details
                Text("Game result details will be displayed here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
}

struct BoxScoreView: View {
    let team: Team
    let isHome: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(team.name) Box Score")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // TODO: Implement box score
                Text("Box score will be displayed here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
}
