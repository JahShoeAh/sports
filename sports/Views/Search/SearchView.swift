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
    @State private var selectedLeague: League?
    
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
                                        print("Clicked: \(category.rawValue). From page: Search. Actions performed: selectedCategory = \(category). TODO: Filter search by \(category.rawValue)")
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
                                BrowseItem(name: "NFL", isActive: true, league: League(id: "NFL", name: "National Football League", abbreviation: "NFL", logoURL: nil, sport: .football, level: .professional, season: "2024-25", isActive: true)),
                                BrowseItem(name: "NBA", isActive: false, league: League(id: "NBA", name: "National Basketball Association", abbreviation: "NBA", logoURL: nil, sport: .basketball, level: .professional, season: "2024-25", isActive: true)),
                                BrowseItem(name: "WNBA", isActive: false, league: League(id: "3", name: "WNBA", abbreviation: "WNBA", logoURL: nil, sport: .basketball, level: .professional, season: "2025", isActive: true)),
                                BrowseItem(name: "MLB", isActive: false, league: League(id: "4", name: "MLB", abbreviation: "MLB", logoURL: nil, sport: .baseball, level: .professional, season: "2025", isActive: true)),
                                BrowseItem(name: "NHL", isActive: false, league: League(id: "5", name: "NHL", abbreviation: "NHL", logoURL: nil, sport: .hockey, level: .professional, season: "2025", isActive: true)),
                                BrowseItem(name: "MLS", isActive: false, league: League(id: "6", name: "MLS", abbreviation: "MLS", logoURL: nil, sport: .soccer, level: .professional, season: "2025", isActive: true)),
                                BrowseItem(name: "EPL", isActive: false, league: League(id: "7", name: "EPL", abbreviation: "EPL", logoURL: nil, sport: .soccer, level: .professional, season: "2025", isActive: true))
                            ], selectedLeague: $selectedLeague)
                            
                            BrowseRow(title: "College", items: [
                                BrowseItem(name: "Football", isActive: false, league: League(id: "8", name: "NCAA Football", abbreviation: "CFB", logoURL: nil, sport: .football, level: .college, season: "2025", isActive: true)),
                                BrowseItem(name: "Men's Basketball", isActive: false, league: League(id: "9", name: "NCAA Men's Basketball", abbreviation: "NCAAM", logoURL: nil, sport: .basketball, level: .college, season: "2025", isActive: true)),
                                BrowseItem(name: "Women's Basketball", isActive: false, league: League(id: "10", name: "NCAA Women's Basketball", abbreviation: "NCAAW", logoURL: nil, sport: .basketball, level: .college, season: "2025", isActive: true)),
                                BrowseItem(name: "Men's Volleyball", isActive: false, league: League(id: "11", name: "NCAA Men's Volleyball", abbreviation: "NCAAVM", logoURL: nil, sport: .volleyball, level: .college, season: "2025", isActive: true)),
                                BrowseItem(name: "Women's Volleyball", isActive: false, league: League(id: "12", name: "NCAA Women's Volleyball", abbreviation: "NCAAVW", logoURL: nil, sport: .volleyball, level: .college, season: "2025", isActive: true)),
                                BrowseItem(name: "Baseball", isActive: false, league: League(id: "13", name: "NCAA Baseball", abbreviation: "NCAA", logoURL: nil, sport: .baseball, level: .college, season: "2025", isActive: true))
                            ], selectedLeague: $selectedLeague)
                            
                            BrowseRow(title: "Olympics", items: [
                                BrowseItem(name: "Olympic Football", isActive: false, league: League(id: "14", name: "Olympic Football", abbreviation: "OLY", logoURL: nil, sport: .football, level: .olympic, season: "2024", isActive: true)),
                                BrowseItem(name: "Olympic Basketball", isActive: false, league: League(id: "15", name: "Olympic Basketball", abbreviation: "OLY", logoURL: nil, sport: .basketball, level: .olympic, season: "2024", isActive: true)),
                                BrowseItem(name: "Olympic Volleyball", isActive: false, league: League(id: "16", name: "Olympic Volleyball", abbreviation: "OLY", logoURL: nil, sport: .volleyball, level: .olympic, season: "2024", isActive: true)),
                                BrowseItem(name: "Olympic Swimming", isActive: false, league: League(id: "17", name: "Olympic Swimming", abbreviation: "OLY", logoURL: nil, sport: .olympic, level: .olympic, season: "2024", isActive: true)),
                                BrowseItem(name: "Olympic Track & Field", isActive: false, league: League(id: "18", name: "Olympic Track & Field", abbreviation: "OLY", logoURL: nil, sport: .olympic, level: .olympic, season: "2024", isActive: true))
                            ], selectedLeague: $selectedLeague)
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
                                        print("Clicked: See All (Staff Lists). From page: Search. Actions performed: none. TODO: Navigate to staff lists")
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
        .sheet(item: $selectedLeague) { league in
            NavigationView {
                LeaguePageView(league: league)
            }
        }
    }
}

struct BrowseItem {
    let name: String
    let isActive: Bool
    let league: League
}

struct BrowseRow: View {
    let title: String
    let items: [BrowseItem]
    @Binding var selectedLeague: League?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.name) { item in
                        Button(action: {
                            print("Clicked: \(item.name). From page: Search. Actions performed: selectedLeague = \(item.league.name)")
                            selectedLeague = item.league
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
                    print("Clicked: See All. From page: Search. Actions performed: none. TODO: Navigate to full list")
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
