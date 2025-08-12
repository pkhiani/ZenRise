import Foundation
import UserNotifications
import os.log

class NotificationManager: ObservableObject {
    private let logger = Logger(subsystem: "com.zenrise.app", category: "NotificationManager")
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var isAuthorized = false
    
    init() {
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
        await notificationCenter.removeAllPendingNotificationRequests()
        logger.info("All alarms cancelled")
    }
    
    private func createNotificationSound(for sound: ClockThemeSettings.AlarmSound) async -> UNNotificationSound {
        if let soundURL = Bundle.main.url(forResource: sound.filename, withExtension: "mp3") {
            do {
                return try UNNotificationSound(named: UNNotificationSoundName(soundURL.lastPathComponent))
            } catch {
                logger.error("Failed to create custom notification sound: \(error.localizedDescription)")
                return .default
            }
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
    }
}
