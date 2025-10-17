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
    
    private var teamsByConferenceAndDivision: [String: [String: [Team]]] {
        var grouped: [String: [String: [Team]]] = [:]
        
        for team in teams {
            let conference = team.conference ?? "Other"
            let division = team.division ?? "Other"
            
            if grouped[conference] == nil {
                grouped[conference] = [:]
            }
            if grouped[conference]?[division] == nil {
                grouped[conference]?[division] = []
            }
            grouped[conference]?[division]?.append(team)
        }
        
        // Sort teams within each division alphabetically
        for conference in grouped.keys {
            if let conferenceDivisions = grouped[conference] {
                for division in conferenceDivisions.keys {
                    grouped[conference]?[division]?.sort { $0.name < $1.name }
                }
            }
        }
        
        return grouped
    }
    
    private var sortedConferences: [String] {
        return teamsByConferenceAndDivision.keys.sorted()
    }
    
    private func sortedDivisions(for conference: String) -> [String] {
        return teamsByConferenceAndDivision[conference]?.keys.sorted() ?? []
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
                            VStack(alignment: .leading, spacing: 16) {
                                // Conference Header
                                HStack {
                                    Text(conference)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    let totalTeams = teamsByConferenceAndDivision[conference]?.values.flatMap { $0 }.count ?? 0
                                    Text("\(totalTeams) teams")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                
                                // Divisions for this conference
                                ForEach(sortedDivisions(for: conference), id: \.self) { division in
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Division Header
                                        HStack {
                                            Text(division)
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            let divisionTeamCount = teamsByConferenceAndDivision[conference]?[division]?.count ?? 0
                                            Text("\(divisionTeamCount) teams")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal)
                                        
                                        // Teams for this division
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 12) {
                                            if let teamsForDivision = teamsByConferenceAndDivision[conference]?[division] {
                                                ForEach(teamsForDivision) { team in
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

// Preview removed - use real data from server instead
