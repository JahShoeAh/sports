//
//  TeamsView.swift
//  sports
//
//  Created by Joyce Zhang on 1/15/25.
//

import SwiftUI

struct TeamsView: View {
    let teams: [Team]
    let isLoading: Bool
    let errorMessage: String?
    let onTeamTap: (Team) -> Void
    
    private var teamsByConference: [String: [Team]] {
        var grouped: [String: [Team]] = [:]
        
        for team in teams {
            let conference = team.conference ?? "Other"
            if grouped[conference] == nil {
                grouped[conference] = []
            }
            grouped[conference]?.append(team)
        }
        
        // Sort teams within each conference alphabetically
        for conference in grouped.keys {
            grouped[conference]?.sort { $0.name < $1.name }
        }
        
        return grouped
    }
    
    private var sortedConferences: [String] {
        return teamsByConference.keys.sorted()
    }
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading teams...")
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
                    
                    Text("Error Loading Teams")
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
            } else if teams.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Teams Found")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("No teams found for this league.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(sortedConferences, id: \.self) { conference in
                            VStack(alignment: .leading, spacing: 12) {
                                // Conference Header
                                HStack {
                                    Text(conference)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(teamsByConference[conference]?.count ?? 0) teams")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                
                                // Teams for this conference
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    if let teamsForConference = teamsByConference[conference] {
                                        ForEach(teamsForConference) { team in
                                            Button(action: {
                                                onTeamTap(team)
                                            }) {
                                                TeamCard(team: team)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}

struct TeamCard: View {
    let team: Team
    
    var body: some View {
        VStack(spacing: 8) {
            // Team Logo
            AsyncImage(url: URL(string: team.logoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "person.3")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 60, height: 60)
            
            // Team Name
            Text(team.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Team City
            Text(team.city)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            // Division (if available)
            if let division = team.division {
                Text(division)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    TeamsView(
        teams: [
            Team(
                id: "1",
                name: "Chiefs",
                city: "Kansas City",
                abbreviation: "KC",
                logoURL: nil,
                league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true),
                conference: "AFC",
                division: "West",
                colors: nil
            ),
            Team(
                id: "2",
                name: "Bills",
                city: "Buffalo",
                abbreviation: "BUF",
                logoURL: nil,
                league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true),
                conference: "AFC",
                division: "East",
                colors: nil
            ),
            Team(
                id: "3",
                name: "Cowboys",
                city: "Dallas",
                abbreviation: "DAL",
                logoURL: nil,
                league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2025", isActive: true),
                conference: "NFC",
                division: "East",
                colors: nil
            )
        ],
        isLoading: false,
        errorMessage: nil,
        onTeamTap: { _ in }
    )
}
