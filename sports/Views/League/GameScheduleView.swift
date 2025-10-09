//
//  GameScheduleView.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import SwiftUI

struct GameScheduleView: View {
    let games: [Game]
    let isLoading: Bool
    let errorMessage: String?
    let onGameTap: (Game) -> Void
    
    @State private var currentDate = Date()
    
    private var gamesByDate: [String: [Game]] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        var grouped: [String: [Game]] = [:]
        
        for game in games {
            let dateString = formatter.string(from: game.gameDate)
            if grouped[dateString] == nil {
                grouped[dateString] = []
            }
            grouped[dateString]?.append(game)
        }
        
        // Sort games within each date by game time
        for date in grouped.keys {
            grouped[date]?.sort { $0.gameTime < $1.gameTime }
        }
        
        return grouped
    }
    
    private var sortedDates: [String] {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        return gamesByDate.keys.sorted { dateString1, dateString2 in
            guard let date1 = formatter.date(from: dateString1),
                  let date2 = formatter.date(from: dateString2) else {
                return false
            }
            return date1 > date2 // Reverse chronological order
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading games...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Error Loading Games")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        // TODO: Implement retry logic
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if games.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Games Found")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("No games scheduled for this season.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(sortedDates, id: \.self) { dateString in
                            VStack(alignment: .leading, spacing: 12) {
                                // Date Header
                                HStack {
                                    Text(dateString)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(gamesByDate[dateString]?.count ?? 0) games")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                
                                // Games for this date - Horizontal scrolling
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        if let gamesForDate = gamesByDate[dateString] {
                                            ForEach(gamesForDate) { game in
                                                Button(action: {
                                                    onGameTap(game)
                                                }) {
                                                    GamePosterCard(game: game)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .frame(width: 200) // Fixed width for horizontal scrolling
                                            }
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
    }
}

#Preview {
    GameScheduleView(
        games: [
            Game(
                id: "1",
                homeTeam: Team(
                    id: "1",
                    name: "Chiefs",
                    city: "Kansas City",
                    abbreviation: "KC",
                    logoURL: nil,
                    league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, isActive: true),
                    conference: "AFC",
                    division: "West",
                    colors: nil
                ),
                awayTeam: Team(
                    id: "2",
                    name: "Bills",
                    city: "Buffalo",
                    abbreviation: "BUF",
                    logoURL: nil,
                    league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, isActive: true),
                    conference: "AFC",
                    division: "East",
                    colors: nil
                ),
                league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, isActive: true),
                season: "2025",
                week: 1,
                gameDate: Date(),
                gameTime: Date(),
                venue: "Arrowhead Stadium",
                city: "Kansas City",
                state: "MO",
                country: "USA",
                homeScore: nil,
                awayScore: nil,
                quarter: nil,
                timeRemaining: nil,
                isLive: false,
                isCompleted: false,
                startingLineups: nil,
                boxScore: nil,
                gameStats: nil
            )
        ],
        isLoading: false,
        errorMessage: nil,
        onGameTap: { _ in }
    )
}
