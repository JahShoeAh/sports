//
//  SearchView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var selectedCategory = SearchCategory.games
    @State private var showingBrowse = false
    
    enum SearchCategory: String, CaseIterable {
        case games = "Games"
        case teams = "Teams"
        case athletes = "Athletes"
        case lists = "Lists"
        case users = "Users"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Search Bar
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search \(selectedCategory.rawValue.lowercased())...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Category Picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(SearchCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                    }) {
                                        Text(category.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedCategory == category ? Color.primary : Color(.systemGray5))
                                            .foregroundColor(selectedCategory == category ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Browse Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Browse")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            BrowseRow(title: "Professional", items: [
                                BrowseItem(name: "NFL", isActive: true),
                                BrowseItem(name: "NBA", isActive: false),
                                BrowseItem(name: "WNBA", isActive: false),
                                BrowseItem(name: "MLB", isActive: false),
                                BrowseItem(name: "NHL", isActive: false),
                                BrowseItem(name: "MLS", isActive: false),
                                BrowseItem(name: "EPL", isActive: false)
                            ])
                            
                            BrowseRow(title: "College", items: [
                                BrowseItem(name: "Football", isActive: false),
                                BrowseItem(name: "Men's Basketball", isActive: false),
                                BrowseItem(name: "Women's Basketball", isActive: false),
                                BrowseItem(name: "Men's Volleyball", isActive: false),
                                BrowseItem(name: "Women's Volleyball", isActive: false),
                                BrowseItem(name: "Baseball", isActive: false)
                            ])
                            
                            BrowseRow(title: "Olympics", items: [
                                BrowseItem(name: "Olympic Football", isActive: false),
                                BrowseItem(name: "Olympic Basketball", isActive: false),
                                BrowseItem(name: "Olympic Volleyball", isActive: false),
                                BrowseItem(name: "Olympic Swimming", isActive: false),
                                BrowseItem(name: "Olympic Track & Field", isActive: false)
                            ])
                        }
                    }
                    
                    // Discover Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Discover")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 16) {
                            DiscoverRow(title: "Live Now", games: []) // TODO: Load live games
                            DiscoverRow(title: "Up Next", games: []) // TODO: Load upcoming games
                            DiscoverRow(title: "Trending", games: []) // TODO: Load trending games
                            
                            // Staff Lists
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Staff's Lists")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Button("See All") {
                                        // TODO: Navigate to staff lists
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        StaffListCard(title: "NBA Game 7s", gameCount: 12)
                                        StaffListCard(title: "NFL Upsets", gameCount: 8)
                                        StaffListCard(title: "Championship Games", gameCount: 15)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Search")
        }
    }
}

struct BrowseItem {
    let name: String
    let isActive: Bool
}

struct BrowseRow: View {
    let title: String
    let items: [BrowseItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.name) { item in
                        Button(action: {
                            // TODO: Handle browse item selection
                        }) {
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(item.isActive ? Color.blue : Color(.systemGray5))
                                .foregroundColor(item.isActive ? .white : .primary)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct DiscoverRow: View {
    let title: String
    let games: [Game]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("See All") {
                    // TODO: Navigate to full list
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if games.isEmpty {
                        // Placeholder cards
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(width: 120, height: 180)
                                .overlay(
                                    Text("Coming Soon")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                )
                        }
                    } else {
                        ForEach(games) { game in
                            GamePosterCard(game: game)
                                .frame(width: 120)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct StaffListCard: View {
    let title: String
    let gameCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text("\(gameCount) games")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(width: 140, height: 80)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SearchView()
}
