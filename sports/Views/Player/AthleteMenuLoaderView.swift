//
//  AthleteMenuLoaderView.swift
//  sports
//
//  Created by Assistant on 10/16/25.
//

import SwiftUI

struct AthleteMenuLoaderView: View {
    let playerId: String
    
    @State private var player: Player?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading player...")
            } else if let errorMessage = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else if let player = player {
                AthleteMenuView(player: player)
            }
        }
        .task {
            await loadPlayer()
        }
    }
    
    private func loadPlayer() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await fetchPlayerWithRetry(playerId: playerId)
            player = fetched
        } catch {
            errorMessage = "Failed to load player: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func fetchPlayerWithRetry(playerId: String, maxRetries: Int = 2) async throws -> Player {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do { return try await YourServerAPI.shared.fetchPlayer(playerId: playerId) }
            catch {
                lastError = error
                if attempt < maxRetries { try? await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1))) }
            }
        }
        throw lastError ?? APIError.networkError("Unknown error")
    }
}


