//
//  GameMenuLoaderView.swift
//  sports
//
//  Created by Assistant on 1/15/25.
//

import SwiftUI

struct GameMenuLoaderView: View {
    let gameId: String
    
    @State private var game: Game?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading game...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Error loading game")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        Task {
                            await loadGame()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let game = game {
                GameMenuView(game: game)
            }
        }
        .task {
            await loadGame()
        }
    }
    
    private func loadGame() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await fetchGameWithRetry(gameId: gameId)
            await MainActor.run {
                self.game = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load game: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func fetchGameWithRetry(gameId: String, maxRetries: Int = 2) async throws -> Game {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do { 
                guard let game = try await YourServerAPI.shared.fetchGame(gameId: gameId, leagueId: "NBA") else {
                    throw APIError.networkError("Game not found")
                }
                return game
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
