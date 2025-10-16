//
//  FeedView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var serverAPI = YourServerAPI.shared
    @StateObject private var firebaseService = FirebaseService.shared
    private let dataManager = SimpleDataManager.shared
    private let cacheService = CacheService.shared
    @State private var games: [Game] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading games...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Error loading games")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        ForEach(games) { game in
                            GamePosterCard(game: game)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Feed")
            .refreshable {
                await loadGames()
            }
        }
        .task {
            await loadGames()
        }
    }
    
    private func loadGames() async {
        isLoading = true
        errorMessage = nil
        
        // 1) Load from cache first
        let cached = dataManager.fetchGames(for: "NBA")
        await MainActor.run {
            self.games = cached
        }
        
        // 2) Ask cache service to refresh if needed (non-blocking UI)
        await cacheService.refreshDataIfNeeded(for: "NBA")
        
        // 3) Try server with retries; on success, save to cache then reload
        do {
            let fetchedGames = try await fetchGamesWithRetry(leagueId: "NBA")
            dataManager.saveGames(fetchedGames, for: "NBA")
            await MainActor.run {
                self.games = dataManager.fetchGames(for: "NBA")
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                // Show error only if nothing in cache
                if self.games.isEmpty {
                    self.errorMessage = "Failed to load games: \(error.localizedDescription)"
                }
                self.isLoading = false
            }
        }
    }
    
    private func fetchGamesWithRetry(leagueId: String, maxRetries: Int = 2) async throws -> [Game] {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                return try await serverAPI.fetchGames(leagueId: leagueId)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
                    continue
                }
            }
        }
        throw lastError ?? APIError.networkError("Unknown error")
    }
}

#Preview {
    FeedView()
}
