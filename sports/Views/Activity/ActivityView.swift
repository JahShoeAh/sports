//
//  ActivityView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct ActivityView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Activity", selection: $selectedTab) {
                    Text("Following").tag(0)
                    Text("You").tag(1)
                    Text("Incoming").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    FollowingView()
                        .tag(0)
                    
                    YouView()
                        .tag(1)
                    
                    IncomingView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Activity")
        }
    }
}

struct FollowingView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<10) { _ in
                    ActivityCard(
                        user: "John Doe",
                        action: "logged",
                        game: "Chiefs vs Bills",
                        timeAgo: "2 hours ago",
                        avatarURL: nil
                    )
                }
            }
            .padding()
        }
    }
}

struct YouView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<5) { _ in
                    ActivityCard(
                        user: "You",
                        action: "logged",
                        game: "Cowboys vs Eagles",
                        timeAgo: "1 day ago",
                        avatarURL: nil
                    )
                }
            }
            .padding()
        }
    }
}

struct IncomingView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<8) { _ in
                    ActivityCard(
                        user: "Jane Smith",
                        action: "liked your review of",
                        game: "Patriots vs Dolphins",
                        timeAgo: "3 hours ago",
                        avatarURL: nil
                    )
                }
            }
            .padding()
        }
    }
}

struct ActivityCard: View {
    let user: String
    let action: String
    let game: String
    let timeAgo: String
    let avatarURL: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user)
                        .fontWeight(.semibold)
                    Text(action)
                    Text(game)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ActivityView()
}
