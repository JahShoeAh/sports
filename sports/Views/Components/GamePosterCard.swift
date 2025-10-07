//
//  GamePosterCard.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct GamePosterCard: View {
    let game: Game
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            print("Clicked: Game Card (\(game.displayTitle)). From page: Feed. Actions performed: none. TODO: Navigate to Game Menu")
            // TODO: Navigate to Game Menu
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Game Poster Image
                ZStack {
                    // Placeholder background
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.3), .red.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .aspectRatio(2/3, contentMode: .fit)
                    
                    // Game text overlay
                    VStack(spacing: 8) {
                        Text(game.leagueDisplayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text(game.displayTitle)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(game.gameDate, style: .date)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(game.gameTime, style: .time)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding()
                }
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Game status indicator
                HStack {
                    if game.isLive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE NOW")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    } else if game.isCompleted {
                        Text("Final")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Upcoming")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let homeScore = game.homeScore, let awayScore = game.awayScore {
                        Text("\(awayScore) - \(homeScore)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    VStack {
        GamePosterCard(game: Game(
            id: "1",
            homeTeam: Team(id: "1", name: "Chiefs", city: "Kansas City", abbreviation: "KC", logoURL: nil, league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true), conference: "AFC", division: "West", colors: nil),
            awayTeam: Team(id: "2", name: "Bills", city: "Buffalo", abbreviation: "BUF", logoURL: nil, league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true), conference: "AFC", division: "East", colors: nil),
            league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true),
            season: "2025",
            week: 1,
            gameDate: Date(),
            gameTime: Date(),
            venue: "Arrowhead Stadium",
            city: "Kansas City",
            state: "MO",
            country: "USA",
            status: .scheduled,
            homeScore: nil,
            awayScore: nil,
            quarter: nil,
            timeRemaining: nil,
            isLive: false,
            isCompleted: false,
            startingLineups: nil,
            boxScore: nil,
            gameStats: nil
        ))
        
        GamePosterCard(game: Game(
            id: "2",
            homeTeam: Team(id: "3", name: "Cowboys", city: "Dallas", abbreviation: "DAL", logoURL: nil, league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true), conference: "NFC", division: "East", colors: nil),
            awayTeam: Team(id: "4", name: "Eagles", city: "Philadelphia", abbreviation: "PHI", logoURL: nil, league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true), conference: "NFC", division: "East", colors: nil),
            league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true),
            season: "2025",
            week: 1,
            gameDate: Date(),
            gameTime: Date(),
            venue: "AT&T Stadium",
            city: "Arlington",
            state: "TX",
            country: "USA",
            status: .live,
            homeScore: 14,
            awayScore: 21,
            quarter: 3,
            timeRemaining: "12:34",
            isLive: true,
            isCompleted: false,
            startingLineups: nil,
            boxScore: nil,
            gameStats: nil
        ))
    }
    .padding()
}
