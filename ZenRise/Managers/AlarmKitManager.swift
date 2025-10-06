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
    
    // Dependencies (will be set by the app)
    weak var settingsManager: UserSettingsManager?
    weak var sleepTracker: SleepBehaviorTracker?
    
    init() {
        setupAlarmObservers()
        checkInitialAuthorizationState()
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
        
        // For test mode, use immediate timer; for real alarms, calculate time until target
        let timeUntilAlarm: TimeInterval
        if isTestMode {
            timeUntilAlarm = 10 // 10 seconds for test
        } else {
            timeUntilAlarm = date.timeIntervalSinceNow
            if timeUntilAlarm <= 0 {
                print("❌ Alarm time has already passed")
                return
            }
        }
        
        print("🔔 Time until alarm: \(timeUntilAlarm) seconds")
        
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
            tintColor: .green
        )
        
        print("🔔 Attributes created - scheduling timer...")
        
        do {
            let timerAlarm = try await alarmManager.schedule(
                id: UUID(),
                configuration: .timer(
                    duration: timeUntilAlarm,
                    attributes: attributes
                )
            )
            
            await MainActor.run {
                self.lastAlarmTime = date
            }
            
            print("✅ Alarm scheduled successfully: \(timerAlarm.id)")
            print("✅ Alarm will fire in \(timeUntilAlarm) seconds")
            
        } catch {
            print("❌ Scheduling error: \(error)")
        }
    }
    
    func cancelAllAlarms() async {
        do {
            let alarms = try alarmManager.alarms
            for alarm in alarms {
                try alarmManager.cancel(id: alarm.id)
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
        
        // Listen for snooze events
        NotificationCenter.default.addObserver(
            forName: .alarmDidSnooze,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAlarmSnoozed()
        }
    }
    
    private func handleAlarmFired() {
        print("🔔 AlarmKit alarm fired!")
        logger.info("AlarmKit alarm fired")
        
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
        
        // Reset snooze count
        currentSnoozeCount = 0
    }
    
    private func handleAlarmSnoozed() {
        print("⏰ AlarmKit alarm snoozed!")
        logger.info("AlarmKit alarm snoozed")
        
        // Update snooze count
        currentSnoozeCount += 1
        
        // Update sleep tracking with snooze pattern
        if let sleepTracker = sleepTracker {
            let today = Calendar.current.startOfDay(for: Date())
            let snoozePattern = SnoozePattern(
                date: today,
                snoozeCount: currentSnoozeCount,
                totalSnoozeTime: TimeInterval(currentSnoozeCount * 300) // 5 minutes per snooze
            )
            
            sleepTracker.addSnoozePattern(snoozePattern)
        }
    }
    
    // MARK: - Test Functions
    
    func scheduleTestAlarm(sound: ClockThemeSettings.AlarmSound) async {
        print("🧪 Scheduling test AlarmKit alarm...")
        let testTime = Date().addingTimeInterval(10) // 10 seconds from now
        await scheduleAlarm(for: testTime, sound: sound, isTestMode: true)
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
            title: LocalizedStringResource(stringLiteral: "Time to wake up!"),
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
        if #available(iOS 16.1, *) {
            // Note: Live Activities authorization check is not available via public API
            // The system will handle this automatically when scheduling activities
            print("🔍 Live Activities: Available (authorization handled by system)")
        } else {
            print("🔍 Live Activities require iOS 16.1+")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let alarmDidFire = Notification.Name("alarmDidFire")
    static let alarmDidSnooze = Notification.Name("alarmDidSnooze")
}
