//
//  ContentView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settingsManager: UserSettingsManager
    @EnvironmentObject var alarmManager: UnifiedAlarmManager
    @EnvironmentObject var quizManager: SleepReadinessQuizManager
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    @State private var selectedTab = 0
    @State private var hasRequestedInitialPermissions = false
    @State private var showQuizFromNotification = false
    
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
                    
                    ProgressTabView(showQuizFromNotification: $showQuizFromNotification)
                        .environmentObject(quizManager)
                        .tabItem {
                            Label("Progress", systemImage: "chart.bar.fill")
                        }
                        .tag(1)
                    
                    SettingsView()
                        .environmentObject(quizManager)
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
                .task {
                    // Check subscription silently in background
                    await checkSubscriptionAndRedirect()
                }
                .onReceive(NotificationCenter.default.publisher(for: .openSleepReadinessQuiz)) { _ in
                    selectedTab = 1 // Switch to Progress tab
                    showQuizFromNotification = true
                }
            } else {
                OnboardingFlowView(hasCompletedOnboarding: $settingsManager.settings.hasCompletedOnboarding)
            }
        }
    }
    
    private func checkSubscriptionAndRedirect() async {
        print("🔍 Starting subscription check...")
        
        // Check if user has completed onboarding
        guard settingsManager.settings.hasCompletedOnboarding else {
            print("ℹ️ User hasn't completed onboarding - skipping subscription check")
            return
        }
        
        // Add timeout to prevent getting stuck
        let hasActiveSubscription = await withTimeout(seconds: 5) {
            await revenueCatManager.checkAndRedirectIfExpired()
        }
        
        await MainActor.run {
            if let hasSubscription = hasActiveSubscription, !hasSubscription {
                // Subscription expired - reset onboarding and redirect to subscription
                print("🔄 Subscription expired - redirecting to onboarding")
                settingsManager.settings.hasCompletedOnboarding = false
                settingsManager.settings.isSubscribed = false
            } else if hasActiveSubscription == nil {
                // Timeout occurred - proceed anyway to avoid blocking user
                print("⚠️ Subscription check timed out - proceeding anyway")
            } else {
                print("✅ Subscription is active - user can continue")
            }
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                return await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
    
    private func requestInitialPermissionsIfNeeded() {
        // Only request permissions once when user first enters the app after onboarding
        guard !hasRequestedInitialPermissions else { return }
        hasRequestedInitialPermissions = true
        
        Task {
            let granted = await alarmManager.requestPermission()
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
                let granted = await alarmManager.requestPermission()
                if granted {
                    await alarmManager.scheduleAlarm(
                        for: wakeUpSchedule.timeUntilTarget.nextWakeUp,
                        sound: settingsManager.settings.themeSettings.selectedSound
                    )
                    // Schedule pre-sleep quiz reminder
                    await alarmManager.schedulePreSleepQuizReminder(
                        for: wakeUpSchedule.timeUntilTarget.nextWakeUp
                    )
                } else {
                    await MainActor.run {
                        settingsManager.settings.isAlarmEnabled = false
                    }
                }
            }
        } else {
            Task {
                await alarmManager.cancelAllAlarms()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSettingsManager())
        .environmentObject(UnifiedAlarmManager())
        .environmentObject(SleepBehaviorTracker())
        .environmentObject(SleepReadinessQuizManager())
}
