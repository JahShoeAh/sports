//
//  sportsApp.swift
//  sports
//
//  Created by Josh Cho on 9/15/25.
//

import SwiftUI
import FirebaseCore
import BackgroundTasks

@main
struct sportsApp: App {
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var dataManager = SimpleDataManager.shared
    @StateObject private var cacheService = CacheService.shared
    
    init() {
        FirebaseApp.configure()
        
        // Register background tasks (disabled for now)
        // cacheService.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            if firebaseService.isAuthenticated && firebaseService.isEmailVerified {
                MainTabView()
                    .environmentObject(dataManager)
                    .environmentObject(cacheService)
            } else if firebaseService.isAuthenticated && firebaseService.needsEmailVerification {
                EmailVerificationView()
            } else {
                AuthenticationView()
            }
        }
        // Background task disabled for now
        // .backgroundTask(.appRefresh("com.sports.refresh")) {
        //     await cacheService.refreshAllData()
        // }
    }
}
