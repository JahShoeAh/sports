//
//  LeaguePageLoaderView.swift
//  sports
//
//  Created by Assistant on 1/15/25.
//

import SwiftUI

struct LeaguePageLoaderView: View {
    let leagueId: String
    
    @State private var league: League?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading league...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Error loading league")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        Task {
                            await loadLeague()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let league = league {
                LeaguePageView(league: league)
            }
        }
        .task {
            await loadLeague()
        }
    }
    
    private func loadLeague() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await fetchLeagueWithRetry(leagueId: leagueId)
            await MainActor.run {
                self.league = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load league: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func fetchLeagueWithRetry(leagueId: String, maxRetries: Int = 2) async throws -> League {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do { 
                let leagues = try await YourServerAPI.shared.fetchLeagues()
                guard let league = leagues.first(where: { $0.id == leagueId }) else {
                    throw APIError.networkError("League not found")
                }
                return league
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
