//
//  ProfileView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var selectedMenu = ProfileMenu.allGames
    @State private var showingSettings = false
    
    enum ProfileMenu: String, CaseIterable {
        case allGames = "All Games"
        case notes = "Notes"
        case likes = "Likes"
        case comments = "Comments"
        case tags = "Tags"
        case watchlist = "Watchlist"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView()
                    
                    // Games by League Chart
                    GamesByLeagueChart()
                    
                    // Recent Games
                    RecentGamesSection()
                    
                    // Profile Menu
                    ProfileMenuSection(selectedMenu: $selectedMenu)
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Clicked: Settings. From page: Profile. Actions performed: showingSettings = true. TODO: Show settings sheet")
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

struct ProfileHeaderView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                )
            
            // User Info
            VStack(spacing: 4) {
                Text(firebaseService.currentUser?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("@\(firebaseService.currentUser?.username ?? "username")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bio = firebaseService.currentUser?.bio {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Follow Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(firebaseService.currentUser?.followers.count ?? 0)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(firebaseService.currentUser?.following.count ?? 0)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct GamesByLeagueChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Games by League")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                LeagueBar(league: "NFL", count: 45, maxCount: 50)
                LeagueBar(league: "NBA", count: 32, maxCount: 50)
                LeagueBar(league: "MLB", count: 28, maxCount: 50)
                LeagueBar(league: "NHL", count: 15, maxCount: 50)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LeagueBar: View {
    let league: String
    let count: Int
    let maxCount: Int
    
    private var barWidth: CGFloat {
        CGFloat(count) / CGFloat(maxCount) * 200
    }
    
    var body: some View {
        HStack {
            Text(league)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .leading)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 200, height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: barWidth, height: 8)
                    .cornerRadius(4)
            }
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct RecentGamesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 120)
                            .overlay(
                                VStack {
                                    Text("Game")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("Poster")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ProfileMenuSection: View {
    @Binding var selectedMenu: ProfileView.ProfileMenu
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(ProfileView.ProfileMenu.allCases, id: \.self) { menu in
                Button(action: {
                    print("Clicked: \(menu.rawValue). From page: Profile. Actions performed: selectedMenu = \(menu). TODO: Show \(menu.rawValue) content")
                    selectedMenu = menu
                }) {
                    HStack {
                        Text(menu.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(selectedMenu == menu ? Color(.systemGray5) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                
                if menu != ProfileView.ProfileMenu.allCases.last {
                    Divider()
                        .padding(.leading)
                }
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    Button("Edit Profile") {
                        print("Clicked: Edit Profile. From page: Settings. Actions performed: showingEditProfile = true. TODO: Navigate to edit profile")
                        showingEditProfile = true
                    }
                    
                    Button("Change Password") {
                        print("Clicked: Change Password. From page: Settings. Actions performed: none. TODO: Navigate to change password")
                        // TODO: Navigate to change password
                    }
                }
                
                Section("Preferences") {
                    Button("Notifications") {
                        print("Clicked: Notifications. From page: Settings. Actions performed: none. TODO: Navigate to notification settings")
                        // TODO: Navigate to notification settings
                    }
                    
                    Button("Privacy") {
                        print("Clicked: Privacy. From page: Settings. Actions performed: none. TODO: Navigate to privacy settings")
                        // TODO: Navigate to privacy settings
                    }
                }
                
                Section("Support") {
                    Button("Help & Support") {
                        print("Clicked: Help & Support. From page: Settings. Actions performed: none. TODO: Navigate to help")
                        // TODO: Navigate to help
                    }
                    
                    Button("About") {
                        print("Clicked: About. From page: Settings. Actions performed: none. TODO: Navigate to about")
                        // TODO: Navigate to about
                    }
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        print("Clicked: Sign Out. From page: Settings. Actions performed: firebaseService.signOut(), dismiss(). TODO: Sign out user and return to auth")
                        try? firebaseService.signOut()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("Clicked: Done. From page: Settings. Actions performed: dismiss(). TODO: Close settings sheet")
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
    }
}

#Preview {
    ProfileView()
}
