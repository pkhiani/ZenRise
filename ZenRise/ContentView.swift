//
//  ContentView.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var themeSettings = ClockThemeSettings()
    @State private var currentWakeUpTime = Date()
    @State private var targetWakeUpTime = Date()
    @State private var isAlarmEnabled = false
    @State private var startDate: Date?
    @State private var selectedTab = 0
    
    private var timeUntilTarget: (days: Int, nextWakeUp: Date) {
        let calendar = Calendar.current
        
        // Extract hours and minutes from both times
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentWakeUpTime)
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetWakeUpTime)
        
        // Convert both times to minutes since midnight
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        let targetMinutes = targetComponents.hour! * 60 + targetComponents.minute!
        
        // Calculate total minutes difference
        var minutesDifference = targetMinutes - currentMinutes
        if minutesDifference > 0 {
            minutesDifference = 24 * 60 - minutesDifference // Reverse the difference since we're waking earlier
        } else {
            minutesDifference = abs(minutesDifference)
        }
        
        // Calculate days needed (15 minutes adjustment per day)
        let daysNeeded = Int(ceil(Double(minutesDifference) / 15.0))
        
        // Calculate next wake up time (15 minutes earlier than current)
        var nextWakeUpComponents = DateComponents()
        let minutesAdjustment = min(15, minutesDifference)
        let adjustedMinutes = (currentMinutes - minutesAdjustment + 24 * 60) % (24 * 60) // Subtract minutes instead of adding
        
        nextWakeUpComponents.hour = adjustedMinutes / 60
        nextWakeUpComponents.minute = adjustedMinutes % 60
        
        let nextWakeUp = calendar.date(from: nextWakeUpComponents) ?? currentWakeUpTime
        
        return (daysNeeded, nextWakeUp)
    }
    
    private var nextWakeUpTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeUntilTarget.nextWakeUp)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                currentWakeUpTime: currentWakeUpTime,
                targetWakeUpTime: targetWakeUpTime,
                isAlarmEnabled: isAlarmEnabled,
                nextWakeUpTimeString: nextWakeUpTimeString,
                timeUntilTarget: timeUntilTarget,
                startDate: startDate,
                themeSettings: themeSettings
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            SettingsView(
                currentWakeUpTime: $currentWakeUpTime,
                targetWakeUpTime: $targetWakeUpTime,
                isAlarmEnabled: $isAlarmEnabled,
                themeSettings: themeSettings
            )
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(1)
        }
        .onChange(of: isAlarmEnabled) { newValue in
            if newValue {
                startDate = Date()
                requestNotificationPermission()
                scheduleNextAlarm()
            } else {
                cancelAlarm()
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
            if !granted {
                isAlarmEnabled = false
            }
        }
    }
    
    private func scheduleNextAlarm() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "ZenRise Alarm"
        content.body = "Time to wake up! 🌅"
        
        // Set custom sound if available
        if let soundURL = Bundle.main.url(forResource: themeSettings.selectedSound.filename, withExtension: "mp3") {
            do {
                content.sound = try UNNotificationSound(named: UNNotificationSoundName(soundURL.lastPathComponent))
            } catch {
                content.sound = .default
                print("Error setting custom sound: \(error)")
            }
        } else {
            content.sound = .default
        }
        
        // Create date components for the next alarm
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.hour, .minute], from: timeUntilTarget.nextWakeUp)
        
        // Set for tomorrow since we're scheduling for the next wake-up
        dateComponents.day = calendar.component(.day, from: Date()) + 1
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: "wakeUpAlarm", content: content, trigger: trigger)
        
        // Schedule notification
        center.add(request)
    }
    
    private func cancelAlarm() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

#Preview {
    ContentView()
}
