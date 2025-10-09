//
//  LogGameView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct LogGameView: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseService = FirebaseService.shared
    
    @State private var entertainmentRating: Double = 5.0
    @State private var selectedReaction: ReactionIcon = .heart
    @State private var selectedViewingMethod: ViewingMethod = .liveOnTV
    @State private var note: String = ""
    @State private var containsSpoilers: Bool = false
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Game Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.displayTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(game.gameDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Entertainment Rating
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Entertainment Value")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("1")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(entertainmentRating))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("10")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $entertainmentRating, in: 1...10, step: 1)
                                .accentColor(.blue)
                        }
                    }
                    
                    // Reaction Icon
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reaction")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            ForEach(ReactionIcon.allCases, id: \.self) { reaction in
                                Button(action: {
                                    print("Clicked: \(reaction.systemImageName) (Reaction). From page: Log Game. Actions performed: selectedReaction = \(reaction). TODO: Select reaction icon")
                                    selectedReaction = reaction
                                }) {
                                    Image(systemName: reaction.systemImageName)
                                        .font(.title2)
                                        .foregroundColor(selectedReaction == reaction ? .red : .gray)
                                        .scaleEffect(selectedReaction == reaction ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: selectedReaction)
                                }
                            }
                        }
                    }
                    
                    // Viewing Method
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Viewing Method")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            ForEach(ViewingMethod.allCases, id: \.self) { method in
                                Button(action: {
                                    print("Clicked: \(method.displayName) (Viewing Method). From page: Log Game. Actions performed: selectedViewingMethod = \(method). TODO: Select viewing method")
                                    selectedViewingMethod = method
                                }) {
                                    HStack {
                                        Text(method.displayName)
                                            .font(.subheadline)
                                        Spacer()
                                        if selectedViewingMethod == method {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(selectedViewingMethod == method ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Note
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a note")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $note)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        if !note.isEmpty {
                            Toggle("Contains spoilers?", isOn: $containsSpoilers)
                                .font(.subheadline)
                        }
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Add Tag
                        HStack {
                            TextField("Add tag", text: $newTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Add") {
                                print("Clicked: Add (Tag). From page: Log Game. Actions performed: tags.append(\(newTag)), newTag = \"\". TODO: Add tag to list")
                                if !newTag.isEmpty && !tags.contains(newTag) {
                                    tags.append(newTag)
                                    newTag = ""
                                }
                            }
                            .disabled(newTag.isEmpty)
                        }
                        
                        // Display Tags
                        if !tags.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack {
                                        Text(tag)
                                            .font(.caption)
                                        Button(action: {
                                            print("Clicked: Remove (\(tag)) (Tag). From page: Log Game. Actions performed: tags.removeAll(\(tag)). TODO: Remove tag from list")
                                            tags.removeAll { $0 == tag }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Log Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("Clicked: Cancel. From page: Log Game. Actions performed: dismiss(). TODO: Close log game sheet")
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("Clicked: Save. From page: Log Game. Actions performed: saveReview(). TODO: Save review to database")
                        Task {
                            await saveReview()
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    private func saveReview() async {
        guard let userId = firebaseService.currentUser?.id else { return }
        
        isLoading = true
        
        let review = Review(
            userId: userId,
            gameId: game.id,
            entertainmentRating: Int(entertainmentRating),
            reactionIcon: selectedReaction,
            viewingMethod: selectedViewingMethod,
            note: note.isEmpty ? nil : note,
            containsSpoilers: containsSpoilers,
            tags: tags
        )
        
        do {
            try await firebaseService.saveReview(review)
            await MainActor.run {
                dismiss()
            }
        } catch {
            // TODO: Handle error
            print("Error saving review: \(error)")
        }
    }
}

#Preview {
    LogGameView(game: Game(
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
