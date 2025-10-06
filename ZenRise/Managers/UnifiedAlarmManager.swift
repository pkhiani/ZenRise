//
//  UnifiedAlarmManager.swift
//  ZenRise
//
//  Created by Pavan Khiani on 2024-12-28.
//

import Foundation
import SwiftUI
import os.log

class UnifiedAlarmManager: ObservableObject {
    private let logger = Logger(subsystem: "com.zenrise.app", category: "UnifiedAlarmManager")
    
    @Published var isAuthorized = false
    @Published var currentSnoozeCount = 0
    @Published var lastAlarmTime: Date?
    
    // Dependencies
    weak var settingsManager: UserSettingsManager?
    weak var sleepTracker: SleepBehaviorTracker?
    
    // Managers
    let notificationManager: NotificationManager
    @available(iOS 26.0, *)
    private lazy var alarmKitManager: AlarmKitManager = {
        let manager = AlarmKitManager()
        manager.settingsManager = settingsManager
        manager.sleepTracker = sleepTracker
        return manager
    }()
    
    init() {
        self.notificationManager = NotificationManager()
        setupObservers()
    }
    
    // MARK: - Setup
    
    func setupDependencies(settingsManager: UserSettingsManager, sleepTracker: SleepBehaviorTracker) {
        self.settingsManager = settingsManager
        self.sleepTracker = sleepTracker
        
        notificationManager.settingsManager = settingsManager
        notificationManager.sleepTracker = sleepTracker
        
        if #available(iOS 26.0, *) {
            alarmKitManager.settingsManager = settingsManager
            alarmKitManager.sleepTracker = sleepTracker
        }
    }
    
    private func setupObservers() {
        // Listen for authorization changes
        notificationManager.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthorized)
        
        if #available(iOS 26.0, *) {
            alarmKitManager.$isAuthorized
                .receive(on: DispatchQueue.main)
                .assign(to: &$isAuthorized)
        }
        
        // Listen for snooze count changes
        notificationManager.$currentSnoozeCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentSnoozeCount)
        
        if #available(iOS 26.0, *) {
            alarmKitManager.$currentSnoozeCount
                .receive(on: DispatchQueue.main)
                .assign(to: &$currentSnoozeCount)
        }
    }
    
    // MARK: - Permissions
    
    func requestPermission() async -> Bool {
        if #available(iOS 26.0, *) {
            // Use AlarmKit exclusively
            let alarmKitGranted = await alarmKitManager.requestPermission()
            if alarmKitGranted {
                logger.info("Using AlarmKit for alarms")
                return true
            } else {
                logger.error("AlarmKit permission denied - alarms will not work")
                return false
            }
        } else {
            logger.error("AlarmKit requires iOS 26.0 or later - alarms will not work")
            return false
        }
    }
    
    // MARK: - Alarm Management
    
    func scheduleAlarm(for date: Date, sound: ClockThemeSettings.AlarmSound, isTestMode: Bool = false) async {
        if #available(iOS 26.0, *) {
            // Use AlarmKit exclusively
            if alarmKitManager.isAuthorized {
                await alarmKitManager.scheduleAlarm(for: date, sound: sound, isTestMode: isTestMode)
            } else {
                logger.error("Cannot schedule alarm - AlarmKit not authorized")
            }
        } else {
            logger.error("Cannot schedule alarm - AlarmKit requires iOS 26.0 or later")
        }
    }
    
    func cancelAllAlarms() async {
        if #available(iOS 26.0, *) {
            await alarmKitManager.cancelAllAlarms()
        } else {
            logger.error("Cannot cancel alarms - AlarmKit requires iOS 26.0 or later")
        }
    }
    
    func schedulePreSleepQuizReminder(for wakeUpTime: Date) async {
        // Quiz reminders always use notifications (AlarmKit doesn't support them)
        await notificationManager.schedulePreSleepQuizReminder(for: wakeUpTime)
    }
    
    // MARK: - Test Functions
    
    func scheduleTestAlarm(sound: ClockThemeSettings.AlarmSound) async {
        if #available(iOS 26.0, *) {
            if alarmKitManager.isAuthorized {
                await alarmKitManager.scheduleTestAlarm(sound: sound)
            } else {
                logger.error("Cannot schedule test alarm - AlarmKit not authorized")
            }
        } else {
            logger.error("Cannot schedule test alarm - AlarmKit requires iOS 26.0 or later")
        }
    }
    
    func scheduleTestQuizNotification() async {
        await notificationManager.scheduleTestQuizNotification()
    }
    
    // MARK: - Utility Functions
    
    func getCurrentAlarmMethod() -> String {
        if #available(iOS 26.0, *) {
            return alarmKitManager.isAuthorized ? "AlarmKit" : "AlarmKit (Not Authorized)"
        }
        return "AlarmKit (iOS 26+ Required)"
    }
    
    func isUsingAlarmKit() -> Bool {
        if #available(iOS 26.0, *) {
            return alarmKitManager.isAuthorized
        }
        return false
    }
    
    func listAllAlarms() async {
        if #available(iOS 26.0, *) {
            await alarmKitManager.listAllAlarms()
        } else {
            print("📋 AlarmKit requires iOS 26.0 or later")
        }
    }
    
    func checkAlarmKitSetup() async {
        if #available(iOS 26.0, *) {
            await alarmKitManager.checkAlarmKitSetup()
        } else {
            print("🔍 AlarmKit requires iOS 26.0 or later")
        }
    }
    
    func scheduleFixedTimeTestAlarm() async {
        if #available(iOS 26.0, *) {
            await alarmKitManager.scheduleFixedTimeTestAlarm()
        } else {
            print("🔍 AlarmKit requires iOS 26.0 or later")
        }
    }
    
    func scheduleImmediateTestAlarm() async {
        if #available(iOS 26.0, *) {
            await alarmKitManager.scheduleImmediateTestAlarm()
        } else {
            print("🔍 AlarmKit requires iOS 26.0 or later")
        }
    }
}
