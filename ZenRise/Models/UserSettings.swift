import Foundation
import SwiftUI
import WidgetKit

struct UserSettings: Codable {
    var currentWakeUpTime: Date
    var targetWakeUpTime: Date
    var isAlarmEnabled: Bool
    var startDate: Date?
    var targetDays: Int? // Original target number of days for the journey
    var themeSettings: ClockThemeSettings
    var hasCompletedOnboarding: Bool
    var isSubscribed: Bool
    
    static let `default` = UserSettings(
        currentWakeUpTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        targetWakeUpTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
        isAlarmEnabled: false,
        startDate: nil,
        targetDays: nil,
        themeSettings: ClockThemeSettings(),
        hasCompletedOnboarding: false,
        isSubscribed: false
    )
}

class UserSettingsManager: ObservableObject {
    @Published var settings: UserSettings {
        didSet {
            saveSettings()
            updateWidgetData()
        }
    }
    
    // Use App Group UserDefaults for sharing data with widget
    private let appGroupIdentifier = "group.com.zenrise.shared"
    private let userDefaults: UserDefaults
    private let settingsKey = "UserSettings"
    
    // Static method to get the appropriate UserDefaults instance
    private static func getUserDefaults(appGroupIdentifier: String) -> UserDefaults {
        // Try to use App Group UserDefaults, fallback to standard if not available
        if let appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            return appGroupDefaults
        } else {
            print("⚠️ App Group UserDefaults not available, using standard UserDefaults")
            return UserDefaults.standard
        }
    }
    
    init() {
        // Initialize userDefaults first
        self.userDefaults = UserSettingsManager.getUserDefaults(appGroupIdentifier: appGroupIdentifier)
        
        // Then initialize settings
        if let data = userDefaults.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = decodedSettings
        } else {
            self.settings = UserSettings.default
        }
        
        // Connect the theme settings to this manager
        self.settings.themeSettings.settingsManager = self
        
        // Initial widget data update
        updateWidgetData()
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    func resetToDefaults() {
        settings = UserSettings.default
    }
    
    func saveSettingsNow() {
        saveSettings()
        updateWidgetData()
    }
    
    /// Update widget data and refresh widget timeline
    func updateWidgetData() {
        let schedule = WakeUpSchedule(
            currentWakeUpTime: settings.currentWakeUpTime,
            targetWakeUpTime: settings.targetWakeUpTime
        )
        
        let widgetData = WidgetData(
            currentWakeUpTime: settings.currentWakeUpTime,
            targetWakeUpTime: settings.targetWakeUpTime,
            isAlarmEnabled: settings.isAlarmEnabled,
            startDate: settings.startDate,
            daysRemaining: schedule.timeUntilTarget.days,
            nextWakeUpTime: schedule.timeUntilTarget.nextWakeUp
        )
        
        widgetData.save()
        
        // Refresh widget timeline
        WidgetCenter.shared.reloadAllTimelines()
    }
}
