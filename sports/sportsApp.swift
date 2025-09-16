//
//  sportsApp.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI
import FirebaseCore

@main
struct sportsApp: App {
    @StateObject private var firebaseService = FirebaseService.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if firebaseService.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}
