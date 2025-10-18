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
    @Environment(\.scenePhase) private var scenePhase
    
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
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .background {
                            print("[sportsApp] App going to background - clearing navigation state")
                            NavigationStateManager.shared.endSession()
                        } else if newPhase == .active {
                            print("[sportsApp] App becoming active - starting new session")
                            NavigationStateManager.shared.startSession()
                        }
                    }
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
