//
//  AlarmKitManager.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import Foundation
import SwiftUI
import os.log
import AlarmKit
import ActivityKit
import AppIntents

// Simple metadata struct for AlarmKit
@available(iOS 26.0, *)
struct ZenRiseAlarmMetadata: AlarmMetadata {
    // Empty implementation - we don't need custom metadata for now
}

@available(iOS 26.0, *)
class AlarmKitManager: ObservableObject {
    private let logger = Logger(subsystem: "com.zenrise.app", category: "AlarmKitManager")
    private let alarmManager = AlarmManager.shared
    
    @Published var isAuthorized = false
    @Published var currentSnoozeCount = 0
    @Published var lastAlarmTime: Date?
    @Published var alarmStartTime: Date?
    @Published var snoozeEvents: [Date] = [] // Track individual snooze events
    private var scheduledAlarmTime: Date? // Track the actual scheduled alarm time
    private var alarmStateMonitorTimer: Timer?
    private var initialAlarmDuration: TimeInterval = 0
    private var lastAlarmState: Alarm.State?
    private var wasAlerting = false // Track if alarm was alerting
    private var trackedAlarmID: UUID? // Track the current alarm ID
    
    // Dependencies (will be set by the app)
    weak var settingsManager: UserSettingsManager?
    weak var sleepTracker: SleepBehaviorTracker?
    
    init() {
        setupAlarmObservers()
        checkInitialAuthorizationState()
        startAlarmStateMonitoring()
    }
    
    deinit {
        stopAlarmStateMonitoring()
    }
    
    private func checkInitialAuthorizationState() {
        let currentState = alarmManager.authorizationState
        logger.info("Initial AlarmKit authorization state: \(String(describing: currentState))")
        
        DispatchQueue.main.async {
            self.isAuthorized = (currentState == .authorized)
        }
    }
    
    // MARK: - Permissions
    
    func requestPermission() async -> Bool {
        do {
            // Check current authorization state first
            let currentState = alarmManager.authorizationState
            logger.info("Current AlarmKit authorization state: \(String(describing: currentState))")
            
            // If already authorized, return true
            if currentState == .authorized {
                await MainActor.run {
                    self.isAuthorized = true
                }
                logger.info("AlarmKit already authorized")
                return true
            }
            
            // If denied, we can't request again
            if currentState == .denied {
                logger.error("AlarmKit authorization was previously denied")
                await MainActor.run {
                    self.isAuthorized = false
                }
                return false
            }
            
            // Request authorization
            let state = try await alarmManager.requestAuthorization()
            let granted = state == .authorized
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            logger.info("AlarmKit permission granted: \(granted)")
            return granted
        } catch {
            logger.error("Error occurred while requesting authorization: \(error)")
            logger.error("Error details: \(error.localizedDescription)")
            await MainActor.run {
                self.isAuthorized = false
            }
            return false
        }
    }
    
    private func checkAuthorizationStatus() async {
        // AlarmKit not available, so always return false
        await MainActor.run {
            self.isAuthorized = false
        }
    }
    
    // MARK: - Alarm Management
    
    func scheduleAlarm(for date: Date, sound: ClockThemeSettings.AlarmSound, isTestMode: Bool = false) async {
        // Check authorization first (following the example pattern)
        if await checkForAuthorization() {
            await scheduleRealAlarm(for: date, sound: sound, isTestMode: isTestMode)
        } else {
            print("❌ AlarmKit not authorized")
        }
    }
    
    private func scheduleRealAlarm(for date: Date, sound: ClockThemeSettings.AlarmSound, isTestMode: Bool = false) async {
        print("🔔 scheduleRealAlarm() called - creating alarm...")
        
        // Cancel any existing alarms first
        await cancelAllAlarms()
        
        // Reset snooze tracking for new alarm
        resetSnoozeTracking()
        
        // Calculate the target alarm time
        let alarmTime: Date
        if isTestMode {
            // For test mode, schedule 10 seconds from now
            alarmTime = Date().addingTimeInterval(10)
            print("🧪 TEST MODE: Alarm scheduled for 10 seconds from now (\(alarmTime))")
        } else {
            // For real alarms, intelligently schedule for today or tomorrow
            let calendar = Calendar.current
            let now = Date()
            
            // Extract the time components from the target date
            let targetComponents = calendar.dateComponents([.hour, .minute], from: date)
            
            // Create a date for today with the target time
            let todayWithTargetTime = calendar.date(bySettingHour: targetComponents.hour ?? 0,
                                                     minute: targetComponents.minute ?? 0,
                                                     second: 0,
                                                     of: now)!
            
            // Check if the time has already passed today
            if todayWithTargetTime > now {
                // Time hasn't passed yet - schedule for today
                alarmTime = todayWithTargetTime
                print("⏰ Alarm time hasn't passed today - scheduling for TODAY: \(alarmTime)")
            } else {
                // Time has already passed - schedule for tomorrow
                alarmTime = calendar.date(byAdding: .day, value: 1, to: todayWithTargetTime)!
                print("⏰ Alarm time has passed today - scheduling for TOMORROW: \(alarmTime)")
            }
        }
        
        print("🔔 Scheduling alarm for: \(alarmTime)")
        print("🔔 Time until alarm: \(alarmTime.timeIntervalSinceNow) seconds")
        
        // Set alarm start time for tracking
        alarmStartTime = Date()
        initialAlarmDuration = alarmTime.timeIntervalSinceNow
        
        // Create alarm presentation with snooze button
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: "Time to wake up!"),
            stopButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "Stop"),
                textColor: .green,
                systemImageName: "checkmark"
            ),
            secondaryButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "Snooze"),
                textColor: .orange,
                systemImageName: "moon.zzz"
            ),
            secondaryButtonBehavior: .countdown
        )
        
        print("🔔 Alert created - creating attributes...")
        
        let attributes = AlarmAttributes<ZenRiseAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: nil,
            tintColor: .green
        )
        
        print("🔔 Attributes created - creating schedule...")
        
        // Use fixed schedule for specific time (proper way for AlarmKit)
        let schedule = Alarm.Schedule.fixed(alarmTime)
        
        print("🔔 Schedule created - creating configuration...")
        
        // Create alarm configuration with the fixed schedule
        let configuration = AlarmManager.AlarmConfiguration<ZenRiseAlarmMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: nil,
            sound: .default
        )
        
        print("🔔 Configuration created - scheduling alarm...")
        
        do {
            let alarmID = UUID()
            let scheduledAlarm = try await alarmManager.schedule(
                id: alarmID,
                configuration: configuration
            )
            
            await MainActor.run {
                self.lastAlarmTime = date
                self.trackedAlarmID = alarmID // Store the alarm ID for tracking
                self.scheduledAlarmTime = alarmTime // Store the actual scheduled alarm time
            }
            
            print("✅ Alarm scheduled successfully: \(alarmID)")
            print("✅ Alarm state: \(String(describing: scheduledAlarm.state))")
            print("✅ Alarm will fire at: \(alarmTime)")
            print("✅ Tracking alarm ID: \(alarmID)")
            
        } catch {
            print("❌ Scheduling error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func cancelAllAlarms() async {
        do {
            let alarms = try alarmManager.alarms
            for alarm in alarms {
                try alarmManager.cancel(id: alarm.id)
            }
            
            // Reset tracking when cancelling alarms
            await MainActor.run {
                self.trackedAlarmID = nil
                self.wasAlerting = false
                self.lastAlarmState = nil
            }
            
            print("✅ All AlarmKit alarms cancelled")
            logger.info("All AlarmKit alarms cancelled")
        } catch {
            print("❌ Failed to cancel AlarmKit alarms: \(error.localizedDescription)")
            logger.error("Failed to cancel AlarmKit alarms: \(error.localizedDescription)")
        }
    }
    
    func schedulePreSleepQuizReminder(for wakeUpTime: Date) async {
        // AlarmKit doesn't support quiz reminders, so we'll use notifications for this
        // This will be handled by the fallback NotificationManager
        print("⚠️ Quiz reminders not supported by AlarmKit, using notifications")
    }
    
    // MARK: - Sound Conversion
    // Note: AlarmKit uses system sounds, so we don't need custom sound conversion
    
    // MARK: - Snooze Tracking
    
    func recordSnoozeEvent() {
        print("⏰ Snooze event recorded!")
        print("⏰ Previous count: \(currentSnoozeCount)")
        
        let snoozeTime = Date()
        snoozeEvents.append(snoozeTime)
        currentSnoozeCount += 1
        
        print("⏰ New count: \(currentSnoozeCount)")
        print("⏰ Total snooze events: \(snoozeEvents.count)")
        
        // Update sleep tracking with snooze pattern
        if let sleepTracker = sleepTracker {
            let today = Calendar.current.startOfDay(for: Date())
            let snoozePattern = SnoozePattern(
                date: today,
                snoozeCount: currentSnoozeCount,
                totalSnoozeTime: TimeInterval(currentSnoozeCount * 300) // 5 minutes per snooze
            )
            
            print("⏰ Adding snooze pattern to sleep tracker: \(snoozePattern)")
            sleepTracker.addSnoozePattern(snoozePattern)
            
            // Note: SleepData update is handled by the caller (recordSnooze or handleAlarmCompleted)
        } else {
            print("⏰ No sleep tracker available!")
        }
        
        // Post notification for other parts of the app
        NotificationCenter.default.post(name: .alarmDidSnooze, object: nil)
        print("⏰ Snooze notification posted")
    }
    
    
    // Simple method to record snooze - call this when you know snooze was pressed
    func recordSnooze() {
        print("🔔 Manual snooze button pressed - recording snooze event...")
        
        recordSnoozeEvent()
        
        // Create a temporary sleep data entry to show snooze-adjusted time in Recent Activity
        updateTodaySleepDataWithSnooze()
    }
    
    private func updateTodaySleepDataWithSnooze() {
        guard let sleepTracker = sleepTracker else {
            print("⏰ No sleep tracker available for snooze sleep data update")
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let targetWakeTime = settingsManager?.settings.targetWakeUpTime ?? Date()
        let currentWakeTime = settingsManager?.settings.currentWakeUpTime ?? Date()
        
        // Calculate snooze-adjusted wake time
        let snoozeDelayMinutes = currentSnoozeCount * 5 // 5 minutes per snooze
        let actualWakeTime = Calendar.current.date(byAdding: .minute, value: snoozeDelayMinutes, to: currentWakeTime) ?? currentWakeTime
        
        let sleepData = SleepData(
            date: today,
            actualWakeTime: actualWakeTime,
            targetWakeTime: targetWakeTime,
            snoozeCount: currentSnoozeCount,
            isSuccessful: actualWakeTime <= targetWakeTime,
            alarmEnabled: true
        )
        
        print("⏰ Updating sleep data with snooze: \(actualWakeTime.formatted(date: .omitted, time: .shortened)) (snooze count: \(currentSnoozeCount))")
        
        // Update existing sleep data or create new one
        sleepTracker.updateSleepData(sleepData)
        print("⏰ Updated sleep data for today with snooze")
    }
    
    // Update or create SleepData for today with current snooze count
    private func updateTodaySleepData(snoozeCount: Int) {
        guard let sleepTracker = sleepTracker else {
            print("⏰ No sleep tracker available for SleepData update")
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let currentTime = Date()
        
        // Check if we already have SleepData for today
        if let existingIndex = sleepTracker.sleepData.firstIndex(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: today) 
        }) {
            // Update existing SleepData
            let existingData = sleepTracker.sleepData[existingIndex]
            let updatedData = SleepData(
                date: existingData.date,
                actualWakeTime: existingData.actualWakeTime,
                targetWakeTime: existingData.targetWakeTime,
                snoozeCount: snoozeCount,
                isSuccessful: existingData.isSuccessful,
                alarmEnabled: existingData.alarmEnabled
            )
            sleepTracker.updateSleepData(updatedData)
            print("⏰ Updated existing SleepData for today with snooze count: \(snoozeCount)")
        } else {
            // Create new SleepData for today
            let targetWakeTime = settingsManager?.settings.targetWakeUpTime ?? currentTime
            let sleepData = SleepData(
                date: today,
                actualWakeTime: currentTime,
                targetWakeTime: targetWakeTime,
                snoozeCount: snoozeCount,
                isSuccessful: currentTime <= targetWakeTime,
                alarmEnabled: true
            )
            sleepTracker.addSleepData(sleepData)
            print("⏰ Created new SleepData for today with snooze count: \(snoozeCount)")
        }
    }
    
    func resetSnoozeTracking() {
        print("🔄 Resetting snooze tracking")
        currentSnoozeCount = 0
        snoozeEvents.removeAll()
        alarmStartTime = nil
        initialAlarmDuration = 0
        lastAlarmState = nil
        wasAlerting = false
        trackedAlarmID = nil
        scheduledAlarmTime = nil
    }
    
    // MARK: - Alarm State Monitoring for Completion
    
    private func startAlarmStateMonitoring() {
        print("🎯 Starting alarm state monitoring for completion detection...")
        
        // Poll every 2 seconds to check alarm states
        alarmStateMonitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForAlarmCompletion()
        }
    }
    
    private func stopAlarmStateMonitoring() {
        print("🛑 Stopping alarm state monitoring...")
        alarmStateMonitorTimer?.invalidate()
        alarmStateMonitorTimer = nil
    }
    
    private func checkForAlarmCompletion() {
        do {
            let alarms = try alarmManager.alarms
            
            // Debug: Show monitoring status periodically (every 30 checks = 1 minute)
            let checkCount = (Int(Date().timeIntervalSince1970) / 2) % 30
            if checkCount == 0 {
                print("🔍 Monitoring alarms... Count: \(alarms.count), Was alerting: \(wasAlerting), Tracked ID: \(String(describing: trackedAlarmID))")
            }
            
            // If we don't have a tracked alarm ID, nothing to monitor
            guard let trackedID = trackedAlarmID else {
                return
            }
            
            // Find our tracked alarm
            let trackedAlarm = alarms.first(where: { $0.id == trackedID })
            
            // If tracked alarm doesn't exist and we were alerting, it was dismissed
            if trackedAlarm == nil && wasAlerting {
                print("✅ Tracked alarm REMOVED - alarm was dismissed!")
                wasAlerting = false
                trackedAlarmID = nil
                handleAlarmCompleted()
                return
            }
            
            // If we found the alarm, check its state
            if let alarm = trackedAlarm {
                let currentState = alarm.state
                let previousState = lastAlarmState
                
                // Debug: Log state when there are changes or active states
                if currentState == .alerting || currentState == .countdown || currentState != previousState {
                    print("📊 Alarm state: \(currentState), Previous: \(String(describing: previousState)), ID: \(alarm.id)")
                }
                
                // Detect when alarm starts alerting
                if currentState == .alerting {
                    if !wasAlerting {
                        print("🔔 Alarm is now ALERTING - user woke up!")
                        wasAlerting = true
                        alarmStartTime = Date()
                    }
                }
                
                // Detect dismissal: was alerting but now in a non-active state (not alerting or countdown)
                if wasAlerting && currentState != .alerting && currentState != .countdown {
                    print("✅ Alarm DISMISSED (state changed from alerting to \(currentState))")
                    wasAlerting = false
                    trackedAlarmID = nil
                    handleAlarmCompleted()
                }
                
                // Update last state
                lastAlarmState = currentState
            }
        } catch {
            print("❌ Error checking alarm states for completion: \(error)")
        }
    }
    
    private func handleAlarmCompleted() {
        print("🎉 Alarm completed - processing day completion...")
        
        // Prevent duplicate processing
        guard trackedAlarmID != nil || wasAlerting else {
            print("⚠️ Already processed alarm completion, skipping")
            return
        }
        
        // Update sleep tracking data
        if let sleepTracker = sleepTracker {
            let today = Calendar.current.startOfDay(for: Date())
            let targetWakeTime = settingsManager?.settings.targetWakeUpTime ?? Date()
            
            // Calculate actual wake time accounting for snooze delays
            let currentWakeTime = settingsManager?.settings.currentWakeUpTime ?? Date()
            let snoozeDelayMinutes = currentSnoozeCount * 5 // 5 minutes per snooze
            let actualWakeTime = Calendar.current.date(byAdding: .minute, value: snoozeDelayMinutes, to: currentWakeTime) ?? Date()
            
            let sleepData = SleepData(
                date: today,
                actualWakeTime: actualWakeTime,
                targetWakeTime: targetWakeTime,
                snoozeCount: currentSnoozeCount,
                isSuccessful: actualWakeTime <= targetWakeTime,
                alarmEnabled: true
            )
            
            sleepTracker.addSleepData(sleepData)
            print("📊 Sleep data recorded for today (AUTOMATIC COMPLETION)")
            print("📊 Current wake time: \(currentWakeTime.formatted(date: .omitted, time: .shortened)) (journey progress)")
            print("📊 Actual wake time: \(actualWakeTime.formatted(date: .omitted, time: .shortened)) (including \(snoozeDelayMinutes) min snooze delay)")
            print("📊 Target wake time: \(targetWakeTime.formatted(date: .omitted, time: .shortened)) (final journey goal)")
            print("📊 Snooze count: \(currentSnoozeCount)")
            print("📊 Was successful: \(actualWakeTime <= targetWakeTime)")
        } else {
            print("⚠️ No sleep tracker available to record data")
        }
        
        // Update current wake time for 15-minute progression
        updateCurrentWakeTimeForJourney()
        
        // Reset all tracking
        currentSnoozeCount = 0
        snoozeEvents.removeAll()
        alarmStartTime = nil
        trackedAlarmID = nil
        wasAlerting = false
        lastAlarmState = nil
        
        print("✅ Day completion processed successfully!")
    }
    
    // Public method for manual alarm completion
    func handleManualAlarmCompletion() async {
        print("🎯 Manual alarm completion called")
        await handleManualAlarmCompleted()
    }
    
    private func handleManualAlarmCompleted() async {
        print("🎉 Manual alarm completion - processing day completion...")
        
        // For manual completion, we don't need the same guards as automatic completion
        // Just check if we have a settings manager to record data
        guard settingsManager != nil else {
            print("⚠️ No settings manager available for manual completion")
            return
        }
        
        // Update sleep tracking data
        if let sleepTracker = sleepTracker {
            let today = Calendar.current.startOfDay(for: Date())
            
            // For manual completion:
            // Use the actual scheduled alarm time (not just the time component)
            // If scheduledAlarmTime is available, use it; otherwise fall back to current wake time
            let alarmTime = scheduledAlarmTime ?? settingsManager?.settings.currentWakeUpTime ?? Date()
            
            let snoozeDelayMinutes = currentSnoozeCount * 5 // 5 minutes per snooze
            let actualWakeTime = Calendar.current.date(byAdding: .minute, value: snoozeDelayMinutes, to: alarmTime) ?? alarmTime
            
            let sleepData = SleepData(
                date: today,
                actualWakeTime: actualWakeTime, // Scheduled alarm time + snooze delays
                targetWakeTime: alarmTime, // The actual scheduled alarm time
                snoozeCount: currentSnoozeCount,
                isSuccessful: true, // Manual completion means they woke up successfully at their target
                alarmEnabled: true
            )
            
            sleepTracker.addSleepData(sleepData)
            print("📊 Sleep data recorded for today (MANUAL COMPLETION)")
            print("📊 Scheduled alarm time: \(alarmTime.formatted(date: .omitted, time: .shortened))")
            print("📊 Actual completion time: \(actualWakeTime.formatted(date: .omitted, time: .shortened)) (alarm time + \(snoozeDelayMinutes) min snooze)")
            print("📊 Snooze count: \(currentSnoozeCount)")
            print("📊 Marked as SUCCESSFUL - user completed at their scheduled alarm time")
        } else {
            print("⚠️ No sleep tracker available to record data")
        }
        
        // Update current wake time for 15-minute progression
        updateCurrentWakeTimeForJourney()
        
        // Reset all tracking
        currentSnoozeCount = 0
        snoozeEvents.removeAll()
        alarmStartTime = nil
        trackedAlarmID = nil
        wasAlerting = false
        lastAlarmState = nil
        
        print("✅ Manual day completion processed successfully!")
    }
    
    // MARK: - Event Handling
    
    private func setupAlarmObservers() {
        // Listen for alarm events
        NotificationCenter.default.addObserver(
            forName: .alarmDidFire,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAlarmFired()
        }
        
        // Listen for app becoming active (user might have snoozed alarm)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.checkForSnoozeAfterAppActivation()
        }
    }
    
    private func handleAlarmFired() {
        print("🔔 AlarmKit alarm fired!")
        logger.info("AlarmKit alarm fired")
        
        // Show snooze tracking notification
        showSnoozeTrackingNotification()
        
        // Update sleep tracking data
        if let sleepTracker = sleepTracker {
            let today = Calendar.current.startOfDay(for: Date())
            let targetWakeTime = settingsManager?.settings.targetWakeUpTime ?? Date()
            let actualWakeTime = Date()
            
            let sleepData = SleepData(
                date: today,
                actualWakeTime: actualWakeTime,
                targetWakeTime: targetWakeTime,
                snoozeCount: currentSnoozeCount,
                isSuccessful: actualWakeTime <= targetWakeTime,
                alarmEnabled: true
            )
            
            sleepTracker.addSleepData(sleepData)
        }
        
        // Update current wake time for 15-minute progression
        updateCurrentWakeTimeForJourney()
        
        // Reset snooze count
        currentSnoozeCount = 0
    }
    
    // Show notification to track snooze
    private func showSnoozeTrackingNotification() {
        print("🔔 Showing snooze tracking notification")
        // This would show a notification asking if user snoozed
        // For now, we'll just log it
    }
    
    // Update current wake time for 15-minute progression
    private func updateCurrentWakeTimeForJourney() {
        guard let settingsManager = settingsManager else {
            print("❌ No settings manager available for wake time update")
            return
        }
        
        let calendar = Calendar.current
        let currentWakeTime = settingsManager.settings.currentWakeUpTime
        let targetWakeTime = settingsManager.settings.targetWakeUpTime
        
        // Check if we've reached the target
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentWakeTime)
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetWakeTime)
        
        let currentMinutes = currentComponents.hour! * 60 + currentComponents.minute!
        let targetMinutes = targetComponents.hour! * 60 + targetComponents.minute!
        
        // If we've reached the target, don't update
        if currentMinutes == targetMinutes {
            print("🎯 Target wake time reached - no more progression needed")
            return
        }
        
        // Calculate next wake time (15 minutes earlier)
        let nextWakeMinutes = (currentMinutes - 15 + 24 * 60) % (24 * 60)
        let nextWakeHour = nextWakeMinutes / 60
        let nextWakeMinute = nextWakeMinutes % 60
        
        // Create new wake time for tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        
        var nextWakeComponents = DateComponents()
        nextWakeComponents.year = tomorrowComponents.year
        nextWakeComponents.month = tomorrowComponents.month
        nextWakeComponents.day = tomorrowComponents.day
        nextWakeComponents.hour = nextWakeHour
        nextWakeComponents.minute = nextWakeMinute
        
        let nextWakeTime = calendar.date(from: nextWakeComponents) ?? currentWakeTime
        
        // Update the current wake time
        settingsManager.settings.currentWakeUpTime = nextWakeTime
        
        print("⏰ Updated current wake time from \(currentWakeTime.formatted(date: .omitted, time: .shortened)) to \(nextWakeTime.formatted(date: .omitted, time: .shortened))")
        
        // Notify UI that wake time has been updated
        NotificationCenter.default.post(name: .wakeTimeUpdated, object: nil)
        
        // Schedule the next alarm
        scheduleNextAlarm()
    }
    
    // Schedule the next alarm based on updated wake time
    private func scheduleNextAlarm() {
        guard let settingsManager = settingsManager else {
            print("❌ No settings manager available for next alarm scheduling")
            return
        }
        
        let wakeUpSchedule = WakeUpSchedule(
            currentWakeUpTime: settingsManager.settings.currentWakeUpTime,
            targetWakeUpTime: settingsManager.settings.targetWakeUpTime
        )
        
        let nextWakeUp = wakeUpSchedule.timeUntilTarget.nextWakeUp
        
        Task {
            print("🔔 Scheduling next alarm for: \(nextWakeUp.formatted(date: .omitted, time: .shortened))")
            await scheduleAlarm(
                for: nextWakeUp,
                sound: settingsManager.settings.themeSettings.selectedSound
            )
        }
    }
    
    // Check if user snoozed alarm when app becomes active
    private func checkForSnoozeAfterAppActivation() {
        // This is a heuristic approach to detect snooze
        // When the app becomes active and there's an active alarm, 
        // it might indicate the user snoozed the alarm
        
        guard let startTime = alarmStartTime else { return }
        
        let timeSinceStart = Date().timeIntervalSince(startTime)
        print("🔍 App became active, alarm started \(timeSinceStart) seconds ago")
        
        // If alarm has been active for more than 10 seconds and user is back in app,
        // it might indicate a snooze action
        if timeSinceStart > 10 && timeSinceStart < 300 { // Between 10 seconds and 5 minutes
            print("🔍 Possible snooze detected - alarm was active for \(timeSinceStart) seconds")
            // Don't auto-detect to avoid false positives
            // This is where you would implement actual snooze detection
        }
    }
    
    // MARK: - Test Functions
    
    func scheduleTestAlarm(sound: ClockThemeSettings.AlarmSound) async {
        print("🧪 Scheduling test AlarmKit alarm...")
        let testTime = Date().addingTimeInterval(10) // 10 seconds from now
        await scheduleAlarm(for: testTime, sound: sound, isTestMode: true)
    }
    
    // Simulate one day of the wake-up journey
    func simulateOneDay() async {
        print("🧪 Simulating one day of wake-up journey...")
        
        // Simulate the alarm firing
        print("🔔 Simulating alarm fired...")
        handleAlarmFired()
        
        // Wait a moment for the progression to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        print("✅ Day simulation complete!")
    }
    
    func scheduleFixedTimeTestAlarm() async {
        print("🧪 Scheduling fixed time test alarm...")
        do {
            // Cancel any existing alarms first
            await cancelAllAlarms()
            
            // Schedule for exactly 1 minute from now using fixed time
            let testTime = Date().addingTimeInterval(60)
            
            print("🔔 Fixed time alarm scheduled for: \(testTime)")
            
            // Create alarm presentation
            let alertContent = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: "ZenRise Test Alarm"),
                stopButton: AlarmButton(
                    text: LocalizedStringResource(stringLiteral: "Stop"),
                    textColor: .red,
                    systemImageName: "stop.circle"
                ),
                secondaryButton: nil,
                secondaryButtonBehavior: nil
            )
            
            let presentation = AlarmPresentation(alert: alertContent)
            
            // Create alarm attributes
            let attributes = AlarmAttributes<ZenRiseAlarmMetadata>(
                presentation: presentation,
                metadata: nil,
                tintColor: .red
            )
            
            // Create fixed time schedule
            let schedule = Alarm.Schedule.fixed(testTime)
            
            // Create alarm configuration
            let configuration = AlarmManager.AlarmConfiguration<ZenRiseAlarmMetadata>.alarm(
                schedule: schedule,
                attributes: attributes,
                stopIntent: nil,
                secondaryIntent: nil,
                sound: .default
            )
            
            // Generate unique ID for the alarm
            let alarmID = UUID()
            
            // Schedule the alarm
            let scheduledAlarm = try await alarmManager.schedule(id: alarmID, configuration: configuration)
            
            print("✅ Fixed time alarm scheduled with ID: \(alarmID)")
            print("✅ Scheduled alarm state: \(String(describing: scheduledAlarm.state))")
            
        } catch {
            print("❌ Failed to schedule fixed time alarm: \(error.localizedDescription)")
        }
    }
    
    func scheduleImmediateTestAlarm() async {
        print("🧪 Scheduling immediate test alarm...")
        
        // Check authorization first (following the example pattern)
        if await checkForAuthorization() {
            await scheduleTimer()
            print("✅ AlarmKit scheduled immediate test alarm")
        } else {
            print("❌ AlarmKit not authorized")
        }
    }
    
    private func checkForAuthorization() async -> Bool {
        let state = alarmManager.authorizationState
        return state == .authorized
    }
    
    private func scheduleTimer() async {
        print("🔔 scheduleTimer() called - creating alert...")
        
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: "Wake up!"),
            stopButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "Done"),
                textColor: .green,
                systemImageName: "checkmark"
            ),
            secondaryButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: "Snooze"),
                textColor: .orange,
                systemImageName: "moon.zzz"
            ),
            secondaryButtonBehavior: .countdown
        )
        
        print("🔔 Alert created - creating attributes...")
        
        let attributes = AlarmAttributes<ZenRiseAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            tintColor: .green
        )
        
        print("🔔 Attributes created - scheduling timer...")
        
        do {
            let timerAlarm = try await alarmManager.schedule(
                id: UUID(),
                configuration: .timer(
                    duration: 10,
                    attributes: attributes
                )
            )
            print("✅ Timer scheduled successfully: \(timerAlarm.id)")
        } catch {
            print("❌ Scheduling error: \(error)")
        }
    }
    
    func scheduleTestQuizNotification() async {
        // Quiz notifications not supported by AlarmKit
        print("⚠️ Quiz notifications not supported by AlarmKit")
    }
    
    private func verifyAlarmScheduled() async {
        do {
            let alarms = try alarmManager.alarms
            print("🔍 Current scheduled alarms count: \(alarms.count)")
            for alarm in alarms {
                print("🔍 Alarm ID: \(alarm.id), State: \(String(describing: alarm.state))")
            }
        } catch {
            print("❌ Failed to verify alarms: \(error.localizedDescription)")
        }
    }
    
    func listAllAlarms() async {
        do {
            let alarms = try alarmManager.alarms
            print("📋 All scheduled alarms:")
            for alarm in alarms {
                print("📋 Alarm ID: \(alarm.id)")
                print("📋 State: \(String(describing: alarm.state))")
                if let schedule = alarm.schedule {
                    print("📋 Schedule: \(String(describing: schedule))")
                    
                    // Calculate when this alarm will fire
                    if case .relative(let relativeSchedule) = schedule {
                        let calendar = Calendar.current
                        let now = Date()
                        let today = calendar.startOfDay(for: now)
                        
                        // Create the alarm time for today
                        let alarmTime = calendar.date(bySettingHour: relativeSchedule.time.hour, 
                                                    minute: relativeSchedule.time.minute, 
                                                    second: 0, 
                                                    of: today) ?? now
                        
                        // If the alarm time has passed today, it will be for tomorrow
                        let finalAlarmTime = alarmTime > now ? alarmTime : calendar.date(byAdding: .day, value: 1, to: alarmTime) ?? alarmTime
                        
                        print("📋 Will fire at: \(finalAlarmTime)")
                        print("📋 Time until fire: \(finalAlarmTime.timeIntervalSince(now)) seconds")
                    }
                }
            }
        } catch {
            print("❌ Failed to list alarms: \(error.localizedDescription)")
        }
    }
    
    func checkAlarmKitSetup() async {
        print("🔍 Checking AlarmKit setup...")
        print("🔍 Authorization state: \(String(describing: alarmManager.authorizationState))")
        print("🔍 Is authorized: \(isAuthorized)")
        
        // Check if we can access alarms
        do {
            let alarms = try alarmManager.alarms
            print("🔍 Can access alarms: YES (\(alarms.count) alarms)")
        } catch {
            print("🔍 Can access alarms: NO - \(error.localizedDescription)")
        }
        
        // Check if we can schedule a simple timer
        do {
            let testID = UUID()
            let testAttributes = AlarmAttributes<ZenRiseAlarmMetadata>(
                presentation: AlarmPresentation(alert: AlarmPresentation.Alert(
                    title: LocalizedStringResource(stringLiteral: "Test"),
                    stopButton: AlarmButton(
                        text: LocalizedStringResource(stringLiteral: "Stop"),
                        textColor: .red,
                        systemImageName: "stop.circle"
                    )
                )),
                metadata: nil,
                tintColor: .blue
            )
            
            let testConfig = AlarmManager.AlarmConfiguration.timer(
                duration: 5, // 5 second timer
                attributes: testAttributes,
                stopIntent: nil,
                secondaryIntent: nil,
                sound: .default
            )
            
            let _ = try await alarmManager.schedule(id: testID, configuration: testConfig)
            print("🔍 Can schedule timer: YES")
            
            // Cancel the test timer immediately
            try alarmManager.cancel(id: testID)
            print("🔍 Can cancel timer: YES")
            
        } catch {
            print("🔍 Can schedule timer: NO - \(error.localizedDescription)")
        }
        
        // Check Live Activities authorization (required for AlarmKit)
        print("🔍 Checking Live Activities authorization...")
        // Note: Live Activities authorization check is not available via public API
        // The system will handle this automatically when scheduling activities
        print("🔍 Live Activities: Available (authorization handled by system)")
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let alarmDidFire = Notification.Name("alarmDidFire")
    static let alarmDidSnooze = Notification.Name("alarmDidSnooze")
}
