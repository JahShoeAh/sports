//
//  TeamMenuLoaderView.swift
//  sports
//
//  Created by Assistant on 1/15/25.
//

import SwiftUI

struct TeamMenuLoaderView: View {
    let teamId: String
    
    @State private var team: Team?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading team...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Error loading team")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        Task {
                            await loadTeam()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let team = team {
                TeamMenuView(team: team)
            }
        }
        .task {
            await loadTeam()
        }
    }
    
    private func loadTeam() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await fetchTeamWithRetry(teamId: teamId)
            await MainActor.run {
                self.team = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load team: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func fetchTeamWithRetry(teamId: String, maxRetries: Int = 2) async throws -> Team {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do { 
                // Try to fetch from all leagues, starting with NBA as default
                let teams = try await YourServerAPI.shared.fetchTeams(leagueId: "NBA")
                if let team = teams.first(where: { $0.id == teamId }) {
                    return team
                }
                
                // If not found in NBA, try other common leagues
                let otherLeagues = ["NFL", "MLB", "NHL"]
                for leagueId in otherLeagues {
                    let otherTeams = try await YourServerAPI.shared.fetchTeams(leagueId: leagueId)
                    if let team = otherTeams.first(where: { $0.id == teamId }) {
                        return team
                    }
                }
                
                throw APIError.networkError("Team not found")
            }
            catch {
                lastError = error
                if attempt < maxRetries { 
                    try? await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1))) 
                }
            }
        }
        throw lastError ?? APIError.networkError("Unknown error")
    }
}
