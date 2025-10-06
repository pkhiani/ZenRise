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
    @StateObject private var alarmManager = UnifiedAlarmManager()
    @StateObject private var sleepTracker = SleepBehaviorTracker()
    @StateObject private var quizManager = SleepReadinessQuizManager()
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
                .environmentObject(alarmManager)
                .environmentObject(sleepTracker)
                .environmentObject(quizManager)
                .environmentObject(revenueCatManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Inject dependencies
        alarmManager.setupDependencies(settingsManager: settingsManager, sleepTracker: sleepTracker)
        
        // Setup notification categories (for quiz reminders and fallback)
        alarmManager.notificationManager.setupNotificationCategories()
        alarmManager.notificationManager.setupQuizReminderCategories()
    }
}
