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
    
    @State private var entertainmentRating: Double? = nil
    @State private var selectedViewingMethod: ViewingMethod? = nil
    @State private var note: String = ""
    @State private var containsSpoilers: Bool = false
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var isLoading = false
    @State private var isLiked = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Game Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.displayTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(game.gameTime, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Entertainment Rating
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Good game?")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Button(action: {
                                print("Clicked: Heart (Like Game). From page: Log Game. Actions performed: isLiked = \(!isLiked). TODO: Save game to liked games")
                                isLiked.toggle()
                            }) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(isLiked ? .red : .gray)
                                    .scaleEffect(isLiked ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: isLiked)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("1")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let rating = entertainmentRating {
                                    Text("\(Int(rating))/10")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                } else {
                                    Text("Tap to rate")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("10")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    // Active track (only show if rating exists)
                                    if let rating = entertainmentRating {
                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(width: (geometry.size.width - 20) * (rating - 1) / 9, height: 4)
                                            .cornerRadius(2)
                                    }
                                    
                                    // Slider thumb (only show if rating exists)
                                    if let rating = entertainmentRating {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 20, height: 20)
                                            .position(x: 10 + (geometry.size.width - 20) * (rating - 1) / 9, y: 10)
                                    }
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            // Calculate new rating based on drag position
                                            let newRating = Double(1 + Int((value.location.x - 10) / (geometry.size.width - 20) * 9))
                                            let clampedRating = max(1, min(10, newRating))
                                            entertainmentRating = clampedRating
                                        }
                                        .onEnded { value in
                                            // Check if this was a tap on the thumb (minimal movement)
                                            if let currentRating = entertainmentRating {
                                                let thumbX = 10 + (geometry.size.width - 20) * (currentRating - 1) / 9
                                                let thumbCenter = CGPoint(x: thumbX, y: 10)
                                                let distance = sqrt(pow(value.startLocation.x - thumbCenter.x, 2) + pow(value.startLocation.y - thumbCenter.y, 2))
                                                let totalDistance = sqrt(pow(value.location.x - value.startLocation.x, 2) + pow(value.location.y - value.startLocation.y, 2))
                                                
                                                // If tap started on thumb and moved less than 5 points, clear rating
                                                if distance <= 10 && totalDistance < 5 {
                                                    entertainmentRating = nil
                                                } else {
                                                    // Otherwise, set rating to final position
                                                    let newRating = Double(1 + Int((value.location.x - 10) / (geometry.size.width - 20) * 9))
                                                    let clampedRating = max(1, min(10, newRating))
                                                    entertainmentRating = clampedRating
                                                }
                                            } else {
                                                // If no rating exists, set it to tapped position
                                                let newRating = Double(1 + Int((value.location.x - 10) / (geometry.size.width - 20) * 9))
                                                let clampedRating = max(1, min(10, newRating))
                                                entertainmentRating = clampedRating
                                            }
                                        }
                                )
                            }
                            .frame(height: 20)
                        }
                    }
                    
                    
                    // Viewing Method
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How'd you watch?")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            ForEach(ViewingMethod.allCases, id: \.self) { method in
                                Button(action: {
                                    if selectedViewingMethod == method {
                                        print("Clicked: \(method.displayName) (Viewing Method - Deselect). From page: Log Game. Actions performed: selectedViewingMethod = nil. TODO: Deselect viewing method")
                                        selectedViewingMethod = nil
                                    } else {
                                        print("Clicked: \(method.displayName) (Viewing Method - Select). From page: Log Game. Actions performed: selectedViewingMethod = \(method). TODO: Select viewing method")
                                        selectedViewingMethod = method
                                    }
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
                        Text("Write something:")
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
            entertainmentRating: entertainmentRating != nil ? Int(entertainmentRating!) : nil,
            reactionIcon: .heart,
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
