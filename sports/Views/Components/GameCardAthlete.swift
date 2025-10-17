//
//  GameCardAthlete.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct GameCardAthlete: View {
    let game: Game
    let athleteTeam: Team
    @State private var isPressed = false
    
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy" // e.g., 4/9/25
        return formatter
    }()
    
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // e.g., Monday
        return formatter
    }()
    
    private var isHomeGame: Bool {
        game.homeTeam.id == athleteTeam.id
    }
    
    private var opposingTeam: Team {
        isHomeGame ? game.awayTeam : game.homeTeam
    }
    
    private var teamMatchup: String {
        if isHomeGame {
            return "\(athleteTeam.abbreviation) vs. \(opposingTeam.abbreviation)"
        } else {
            return "\(athleteTeam.abbreviation) @ \(opposingTeam.abbreviation)"
        }
    }
    
    var body: some View {
        NavigationLink(destination: GameMenuLoaderView(gameId: game.id)) {
            VStack(alignment: .leading, spacing: 0) {
                // HOME/AWAY label at the top
                HStack {
                    Text(isHomeGame ? "HOME" : "AWAY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isHomeGame ? Color.green : Color.blue)
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Main content area
                HStack(alignment: .center, spacing: 16) {
                    // Left side - Date and time information
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Self.dayFormatter.string(from: game.gameTime))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(Self.shortDateFormatter.string(from: game.gameTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(game.gameTime, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right side - Team matchup
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(teamMatchup)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Bottom section - Game status and score
                HStack {
                    if game.isLive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
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
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// Preview removed - use real data from server instead
