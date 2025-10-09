//
//  GameReviewsView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct GameReviewsView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var selectedTab = 0
    @State private var reviews: [Review] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Reviews", selection: $selectedTab) {
                    Text("All").tag(0)
                    Text("You").tag(1)
                    Text("Following").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    AllReviewsView(reviews: reviews, isLoading: isLoading)
                        .tag(0)
                    
                    YourReviewsView(game: game, isLoading: isLoading)
                        .tag(1)
                    
                    FollowingReviewsView(reviews: reviews, isLoading: isLoading)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("Clicked: Done. From page: Game Reviews. Actions performed: dismiss(). TODO: Close reviews sheet")
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadReviews()
        }
    }
    
    private func loadReviews() async {
        isLoading = true
        
        do {
            let fetchedReviews = try await firebaseService.fetchReviews(for: game.id)
            await MainActor.run {
                self.reviews = fetchedReviews
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct AllReviewsView: View {
    let reviews: [Review]
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading reviews...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reviews.isEmpty {
                    VStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No reviews yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Be the first to review this game!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(reviews) { review in
                        ReviewCard(review: review)
                    }
                }
            }
            .padding()
        }
    }
}

struct YourReviewsView: View {
    let game: Game
    let isLoading: Bool
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var userReviews: [Review] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading your reviews...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if userReviews.isEmpty {
                    VStack {
                        Image(systemName: "star")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No reviews from you")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Log this game to share your thoughts!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(userReviews) { review in
                        ReviewCard(review: review)
                    }
                }
            }
            .padding()
        }
        .task {
            await loadUserReviews()
        }
    }
    
    private func loadUserReviews() async {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        do {
            let allUserReviews = try await firebaseService.fetchUserReviews(userId: userId)
            let gameReviews = allUserReviews.filter { $0.gameId == game.id }
            await MainActor.run {
                self.userReviews = gameReviews
            }
        } catch {
            print("Error loading user reviews: \(error)")
        }
    }
}

struct FollowingReviewsView: View {
    let reviews: [Review]
    let isLoading: Bool
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var followingReviews: [Review] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading following reviews...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if followingReviews.isEmpty {
                    VStack {
                        Image(systemName: "person.2")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No reviews from people you follow")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Follow more people to see their reviews here!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(followingReviews) { review in
                        ReviewCard(review: review)
                    }
                }
            }
            .padding()
        }
        .task {
            await loadFollowingReviews()
        }
    }
    
    private func loadFollowingReviews() async {
        guard let currentUser = firebaseService.currentUser else { return }
        
        let followingUserIds = currentUser.following
        let followingReviews = reviews.filter { followingUserIds.contains($0.userId) }
        
        await MainActor.run {
            self.followingReviews = followingReviews
        }
    }
}

struct ReviewCard: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.user?.displayName ?? "User")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(review.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Rating
                HStack(spacing: 2) {
                    ForEach(1...10, id: \.self) { star in
                        Image(systemName: star <= review.entertainmentRating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(star <= review.entertainmentRating ? .yellow : .gray)
                    }
                }
            }
            
            // Reaction and Viewing Method
            HStack {
                Image(systemName: review.reactionIcon.systemImageName)
                    .foregroundColor(.red)
                
                Text(review.viewingMethod.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Note
            if let note = review.note {
                VStack(alignment: .leading, spacing: 4) {
                    if review.containsSpoilers {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Contains spoilers")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text(note)
                        .font(.subheadline)
                }
            }
            
            // Tags
            if !review.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(review.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    GameReviewsView(game: Game(
        id: "1",
        homeTeam: Team(id: "1", name: "Chiefs", city: "Kansas City", abbreviation: "KC", logoURL: nil, league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, isActive: true), conference: "AFC", division: "West", colors: nil),
        awayTeam: Team(id: "2", name: "Bills", city: "Buffalo", abbreviation: "BUF", logoURL: nil, league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, isActive: true), conference: "AFC", division: "East", colors: nil),
        league: League(id: "1", name: "NFL", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, isActive: true),
        season: "2025",
        week: 1,
        gameDate: Date(),
        gameTime: Date(),
        venue: "Arrowhead Stadium",
        city: "Kansas City",
        state: "MO",
        country: "USA",
        homeScore: 24,
        awayScore: 21,
        quarter: 4,
        timeRemaining: "0:00",
        isLive: false,
        isCompleted: true,
        startingLineups: nil,
        boxScore: nil,
        gameStats: nil
    ))
}
