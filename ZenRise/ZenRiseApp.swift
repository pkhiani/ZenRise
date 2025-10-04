//
//  ZenRiseApp.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI
import UserNotifications

@main
struct ZenRiseApp: App {
    @StateObject private var settingsManager = UserSettingsManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var sleepTracker = SleepBehaviorTracker()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
                .environmentObject(notificationManager)
                .environmentObject(sleepTracker)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Inject dependencies
        notificationManager.settingsManager = settingsManager
        notificationManager.sleepTracker = sleepTracker
        
        // Setup notification categories
        notificationManager.setupNotificationCategories()
    }
}
