import Foundation
import UserNotifications
import os.log
import SwiftUI

class NotificationManager: NSObject, ObservableObject {
    private let logger = Logger(subsystem: "com.zenrise.app", category: "NotificationManager")
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var isAuthorized = false
    @Published var currentSnoozeCount = 0
    @Published var lastAlarmTime: Date?
    
    // Dependencies (will be set by the app)
    weak var settingsManager: UserSettingsManager?
    weak var sleepTracker: SleepBehaviorTracker?
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            logger.info("Notification permission granted: \(granted)")
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleAlarm(for wakeUpTime: Date, sound: ClockThemeSettings.AlarmSound) async {
        await cancelAllAlarms()
        
        // Reset snooze count and store alarm time
        currentSnoozeCount = 0
        lastAlarmTime = wakeUpTime
        
        let content = UNMutableNotificationContent()
        content.title = "ZenRise Alarm"
        content.body = "Time to wake up! 🌅"
        content.sound = await createNotificationSound(for: sound)
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.hour, .minute], from: wakeUpTime)
        dateComponents.day = calendar.component(.day, from: Date()) + 1
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "wakeUpAlarm", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            logger.info("Alarm scheduled for \(wakeUpTime)")
        } catch {
            logger.error("Failed to schedule alarm: \(error.localizedDescription)")
        }
    }
    
    func cancelAllAlarms() async {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.info("All alarms cancelled")
    }
    
    private func createNotificationSound(for sound: ClockThemeSettings.AlarmSound) async -> UNNotificationSound {
        if let soundURL = Bundle.main.url(forResource: sound.filename, withExtension: "mp3") {
            return UNNotificationSound(named: UNNotificationSoundName(soundURL.lastPathComponent))
        }
        return .default
    }
    
    func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 5 minutes",
            options: []
        )
        
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "Stop Alarm",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([category])
        
        // Set up notification response handler
        notificationCenter.delegate = self
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            handleSnooze()
        case "STOP_ACTION":
            handleStopAlarm()
        default:
            break
        }
    }
    
    private func handleSnooze() {
        self.currentSnoozeCount += 1
        logger.info("Snooze triggered. Count: \(self.currentSnoozeCount)")
        
        // Schedule next alarm in 5 minutes
        let snoozeTime = Date().addingTimeInterval(300) // 5 minutes
        Task {
            await scheduleSnoozeAlarm(for: snoozeTime)
        }
    }
    
    private func handleStopAlarm() {
        logger.info("Alarm stopped. Total snoozes: \(self.currentSnoozeCount)")
        
        // Record the sleep data
        if self.lastAlarmTime != nil {
            recordSleepData(actualWakeTime: Date(), snoozeCount: self.currentSnoozeCount)
        }
        
        // Reset snooze count
        self.currentSnoozeCount = 0
        self.lastAlarmTime = nil
    }
    
    private func scheduleSnoozeAlarm(for time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "ZenRise Alarm"
        content.body = "Time to wake up! 🌅"
        content.sound = .default
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "snoozeAlarm", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            logger.info("Snooze alarm scheduled for \(time)")
        } catch {
            logger.error("Failed to schedule snooze alarm: \(error.localizedDescription)")
        }
    }
    
    private func recordSleepData(actualWakeTime: Date, snoozeCount: Int) {
        // Get current target wake time from settings
        guard let settingsManager = getSettingsManager() else {
            logger.error("Could not access settings manager")
            return
        }
        
        let targetWakeTime = settingsManager.settings.targetWakeUpTime
        
        // Create sleep data entry
        let sleepData = SleepData(
            date: Calendar.current.startOfDay(for: actualWakeTime),
            actualWakeTime: actualWakeTime,
            targetWakeTime: targetWakeTime,
            snoozeCount: snoozeCount,
            isSuccessful: actualWakeTime <= targetWakeTime,
            alarmEnabled: true
        )
        
        // Record the data
        getSleepTracker()?.addSleepData(sleepData)
        
        // Record snooze pattern if there were snoozes
        if snoozeCount > 0 {
            let snoozePattern = SnoozePattern(
                date: Calendar.current.startOfDay(for: actualWakeTime),
                snoozeCount: snoozeCount,
                totalSnoozeTime: TimeInterval(snoozeCount * 300) // 5 minutes per snooze
            )
            getSleepTracker()?.addSnoozePattern(snoozePattern)
        }
        
        logger.info("Recorded sleep data: wake time \(actualWakeTime), snoozes \(snoozeCount)")
    }
    
    // Helper methods to access managers
    private func getSettingsManager() -> UserSettingsManager? {
        return settingsManager
    }
    
    private func getSleepTracker() -> SleepBehaviorTracker? {
        return sleepTracker
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleNotificationResponse(response)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
