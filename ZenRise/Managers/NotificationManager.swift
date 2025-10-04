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
    
    func scheduleAlarm(for wakeUpTime: Date, sound: ClockThemeSettings.AlarmSound, isTestMode: Bool = false) async {
        print("🔔 NotificationManager.scheduleAlarm called")
        print("🔔 Wake up time: \(wakeUpTime)")
        print("🔔 Sound: \(sound.rawValue)")
        
        await cancelAllAlarms()
        
        // Reset snooze count and store alarm time
        currentSnoozeCount = 0
        lastAlarmTime = wakeUpTime
        
        let content = UNMutableNotificationContent()
        content.title = "ZenRise Alarm"
        content.body = "Time to wake up! 🌅"
        content.sound = await createNotificationSound(for: sound)
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        let trigger: UNNotificationTrigger
        
        if isTestMode {
            // For testing: schedule alarm 10 seconds from now
            let testTime = Date().addingTimeInterval(10)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            print("🧪 TEST MODE: Alarm scheduled for 10 seconds from now (\(testTime))")
        } else {
            // Normal mode: use the provided wake-up time
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: wakeUpTime)
            
            print("🔔 Date components for trigger: \(dateComponents)")
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }
        let request = UNNotificationRequest(identifier: "wakeUpAlarm", content: content, trigger: trigger)
        
        do {
            // Ensure notification categories are set up
            setupNotificationCategories()
            
            try await notificationCenter.add(request)
            print("✅ Alarm successfully scheduled for \(wakeUpTime)")
            logger.info("Alarm scheduled for \(wakeUpTime)")
        } catch {
            print("❌ Failed to schedule alarm: \(error.localizedDescription)")
            logger.error("Failed to schedule alarm: \(error.localizedDescription)")
        }
    }
    
    func cancelAllAlarms() async {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.info("All alarms cancelled")
    }
    
    // MARK: - Test Functions
    func scheduleTestAlarm(sound: ClockThemeSettings.AlarmSound) async {
        print("🧪 Scheduling test alarm...")
        await scheduleAlarm(for: Date(), sound: sound, isTestMode: true)
    }
    
    private func createNotificationSound(for sound: ClockThemeSettings.AlarmSound) async -> UNNotificationSound {
        print("🔊 Creating notification sound for: \(sound.rawValue)")
        print("🔊 Looking for file: \(sound.filename).mp3")
        
        // First, check if file exists in bundle
        if let soundURL = Bundle.main.url(forResource: sound.filename, withExtension: "mp3") {
            print("✅ Found sound file at: \(soundURL)")
            print("🔊 File name: \(soundURL.lastPathComponent)")
            
            // Check file size (iOS has restrictions on notification sounds)
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: soundURL.path)
                if let fileSize = fileAttributes[.size] as? Int {
                    print("🔊 Sound file size: \(fileSize) bytes (\(fileSize / 1024) KB)")
                    if fileSize > 30 * 1024 * 1024 { // 30MB limit
                        print("⚠️ Sound file too large for notifications, using default")
                        return .default
                    }
                }
            } catch {
                print("⚠️ Could not check file attributes: \(error)")
            }
            
            // Try different approaches to create the notification sound
            let fullFilename = "\(sound.filename).mp3"
            print("🔊 Attempting to use custom sound: \(fullFilename)")
            
            // Method 1: Use full filename
            let customSound = UNNotificationSound(named: UNNotificationSoundName(fullFilename))
            print("🔊 Created custom notification sound: \(customSound)")
            return customSound
            
        } else {
            print("❌ Sound file not found: \(sound.filename).mp3")
            print("🔊 Available resources in bundle:")
            if let resourcePath = Bundle.main.resourcePath {
                let resourceURL = URL(fileURLWithPath: resourcePath)
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
                    let mp3Files = contents.filter { $0.pathExtension == "mp3" }
                    for file in mp3Files {
                        print("🔊 Found MP3: \(file.lastPathComponent)")
                    }
                } catch {
                    print("🔊 Could not list bundle contents: \(error)")
                }
            }
            print("🔊 Falling back to default sound")
            return .default
        }
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
        print("🔍 DEBUG: handleSnooze called")
        print("🔍 DEBUG: currentSnoozeCount before increment: \(self.currentSnoozeCount)")
        
        self.currentSnoozeCount += 1
        
        print("⏰ Snooze triggered! Count: \(self.currentSnoozeCount)")
        print("🔍 DEBUG: currentSnoozeCount after increment: \(self.currentSnoozeCount)")
        logger.info("Snooze triggered. Count: \(self.currentSnoozeCount)")
        
        // Record snooze data for analytics
        print("🔍 DEBUG: About to call recordSnoozeData")
        recordSnoozeData()
        
        // Schedule next alarm in 5 minutes
        let snoozeTime = Date().addingTimeInterval(300) // 5 minutes
        print("⏰ Scheduling snooze alarm for \(snoozeTime)")
        
        Task {
            await scheduleSnoozeAlarm(for: snoozeTime)
        }
    }
    
    private func handleStopAlarm() {
        print("🔍 DEBUG: handleStopAlarm called")
        print("🔍 DEBUG: Final snooze count before reset: \(self.currentSnoozeCount)")
        logger.info("Alarm stopped. Total snoozes: \(self.currentSnoozeCount)")
        
        // Record the sleep data
        if self.lastAlarmTime != nil {
            print("🔍 DEBUG: Recording final sleep data")
            recordSleepData(actualWakeTime: Date(), snoozeCount: self.currentSnoozeCount)
        }
        
        // Reset snooze count
        print("🔍 DEBUG: Resetting snooze count from \(self.currentSnoozeCount) to 0")
        self.currentSnoozeCount = 0
        self.lastAlarmTime = nil
        print("🔍 DEBUG: Snooze count reset complete")
    }
    
    private func scheduleSnoozeAlarm(for time: Date) async {
        // Get the current selected sound from settings
        let selectedSound = settingsManager?.settings.themeSettings.selectedSound ?? .gentle
        
        let content = UNMutableNotificationContent()
        content.title = "ZenRise Alarm - Snooze"
        content.body = "Time to wake up! 🌅 (Snooze #\(self.currentSnoozeCount))"
        content.sound = await createNotificationSound(for: selectedSound)
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "snoozeAlarm_\(currentSnoozeCount)", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("⏰ Snooze alarm #\(currentSnoozeCount) scheduled for \(time)")
            logger.info("Snooze alarm scheduled for \(time)")
        } catch {
            print("❌ Failed to schedule snooze alarm: \(error.localizedDescription)")
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
        
        logger.info("Recorded sleep data: wake time \(actualWakeTime), snoozes \(snoozeCount)")
    }
    
    private func recordSnoozeData() {
        guard let sleepTracker = getSleepTracker() else {
            print("❌ Could not access sleep tracker for snooze data")
            logger.error("Could not access sleep tracker for snooze data")
            return
        }
        
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async {
            let today = Calendar.current.startOfDay(for: Date())
            
            // Get the user's target wake time from settings
            let targetWakeTime = self.getSettingsManager()?.settings.targetWakeUpTime ?? Date()
            let actualWakeTime = Date() // Current time when snoozing
            
            let sleepData = SleepData(
                date: today,
                actualWakeTime: actualWakeTime,
                targetWakeTime: targetWakeTime,
                snoozeCount: self.currentSnoozeCount,
                isSuccessful: actualWakeTime <= targetWakeTime,
                alarmEnabled: true
            )
            
            print("📊 About to record sleep data: \(sleepData)")
            print("📊 Sleep tracker before: \(sleepTracker.sleepData.count) sleep data entries")
            
            sleepTracker.addSleepData(sleepData)
            
            print("📊 Sleep tracker after: \(sleepTracker.sleepData.count) sleep data entries")
            print("📊 Recorded snooze data: \(self.currentSnoozeCount) snoozes today")
            print("📊 All sleep data: \(sleepTracker.sleepData)")
            
            self.logger.info("Recorded snooze data: \(self.currentSnoozeCount) snoozes")
        }
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
