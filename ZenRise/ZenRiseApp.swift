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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
                .environmentObject(notificationManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Setup notification categories
        notificationManager.setupNotificationCategories()
        
        // Request notification permission if not already granted
        if !notificationManager.isAuthorized {
            Task {
                await notificationManager.requestPermission()
            }
        }
    }
}
