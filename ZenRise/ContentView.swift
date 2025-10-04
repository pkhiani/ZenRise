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
    @State private var hasRequestedInitialPermissions = false
    
    private var wakeUpSchedule: WakeUpSchedule {
        WakeUpSchedule(
            currentWakeUpTime: settingsManager.settings.currentWakeUpTime,
            targetWakeUpTime: settingsManager.settings.targetWakeUpTime
        )
    }
    
    var body: some View {
        Group {
            if settingsManager.settings.hasCompletedOnboarding {
                TabView(selection: $selectedTab) {
                    HomeView(wakeUpSchedule: wakeUpSchedule)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    ProgressTabView()
                        .tabItem {
                            Label("Progress", systemImage: "chart.bar.fill")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(2)
                }
                .onChange(of: settingsManager.settings.isAlarmEnabled) { isEnabled in
                    handleAlarmToggle(isEnabled: isEnabled)
                }
                .onAppear {
                    requestInitialPermissionsIfNeeded()
                }
            } else {
                OnboardingFlowView(hasCompletedOnboarding: $settingsManager.settings.hasCompletedOnboarding)
            }
        }
    }
    
    private func requestInitialPermissionsIfNeeded() {
        // Only request permissions once when user first enters the app after onboarding
        guard !hasRequestedInitialPermissions else { return }
        hasRequestedInitialPermissions = true
        
        Task {
            let granted = await notificationManager.requestPermission()
            await MainActor.run {
                if !granted {
                    // If permissions were denied, we'll show a helpful message
                    // The user can still use the app but alarms won't work
                    print("Notification permissions denied - alarms will not work")
                }
            }
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
