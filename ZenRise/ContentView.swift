//
//  ContentView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTab = 0
    
    private var wakeUpSchedule: WakeUpSchedule {
        WakeUpSchedule(
            currentWakeUpTime: settingsManager.settings.currentWakeUpTime,
            targetWakeUpTime: settingsManager.settings.targetWakeUpTime
        )
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(wakeUpSchedule: wakeUpSchedule)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
        }
        .onChange(of: settingsManager.settings.isAlarmEnabled) { isEnabled in
            handleAlarmToggle(isEnabled: isEnabled)
        }
    }
    
    private func handleAlarmToggle(isEnabled: Bool) {
        if isEnabled {
            settingsManager.settings.startDate = Date()
            Task {
                let granted = await notificationManager.requestPermission()
                if granted {
                    await notificationManager.scheduleAlarm(
                        for: wakeUpSchedule.timeUntilTarget.nextWakeUp,
                        sound: settingsManager.settings.themeSettings.selectedSound
                    )
                } else {
                    await MainActor.run {
                        settingsManager.settings.isAlarmEnabled = false
                    }
                }
            }
        } else {
            Task {
                await notificationManager.cancelAllAlarms()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSettingsManager())
        .environmentObject(NotificationManager())
}
