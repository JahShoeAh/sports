//
//  MainTabView.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Feed")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)
            
            ActivityView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Activity")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.primary)
    }
}

#Preview {
    MainTabView()
}
