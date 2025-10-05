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
    @StateObject private var quizManager = SleepReadinessQuizManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
                .environmentObject(notificationManager)
                .environmentObject(sleepTracker)
                .environmentObject(quizManager)
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
        notificationManager.setupQuizReminderCategories()
    }
}
