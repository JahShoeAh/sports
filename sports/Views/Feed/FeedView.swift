//
//  FeedView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var apiService = APIService.shared
    @StateObject private var firebaseService = FirebaseService.shared
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
        
        do {
            let fetchedGames = try await apiService.fetchNFLGames()
            await MainActor.run {
                self.games = fetchedGames
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

#Preview {
    FeedView()
}
