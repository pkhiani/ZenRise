import Foundation

struct AppConfig {
    static let appName = "ZenRise"
    static let appVersion = "1.0.0"
    static let bundleIdentifier = "com.zenrise.app"
    
    struct Notification {
        static let alarmCategoryIdentifier = "ALARM_CATEGORY"
        static let snoozeActionIdentifier = "SNOOZE_ACTION"
        static let stopActionIdentifier = "STOP_ACTION"
        static let alarmIdentifier = "wakeUpAlarm"
    }
    
    struct UserDefaults {
        static let settingsKey = "UserSettings"
    }
    
    struct WakeUp {
        static let adjustmentMinutesPerDay = 15
        static let maxDaysToTarget = 30 // Safety limit
    }
    
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let shadowRadius: CGFloat = 2
        static let animationDuration: Double = 0.3
    }
    
    struct RevenueCat {
        static let apiKey = "appl_yUCWFsogwJtYxkgqvKZrauozjRx" // Replace with your actual API key
        static let premiumEntitlement = "premium"
        static let freeTrialDays = 3
    }
}
