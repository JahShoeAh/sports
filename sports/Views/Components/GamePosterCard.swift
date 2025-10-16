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
    
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy" // e.g., 4/9/25
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: GameMenuView(game: game)) {
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
                        Text(game.league.abbreviation)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text("\(game.awayTeam.abbreviation) vs. \(game.homeTeam.abbreviation)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(Self.shortDateFormatter.string(from: game.gameTime))
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

// Preview removed - use real data from server instead
