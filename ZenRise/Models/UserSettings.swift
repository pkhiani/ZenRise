import Foundation
import SwiftUI

struct UserSettings: Codable {
    var currentWakeUpTime: Date
    var targetWakeUpTime: Date
    var isAlarmEnabled: Bool
    var startDate: Date?
    var themeSettings: ClockThemeSettings
    var hasCompletedOnboarding: Bool
    var isSubscribed: Bool
    
    static let `default` = UserSettings(
        currentWakeUpTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        targetWakeUpTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
        isAlarmEnabled: false,
        startDate: nil,
        themeSettings: ClockThemeSettings(),
        hasCompletedOnboarding: false,
        isSubscribed: false
    )
}

class UserSettingsManager: ObservableObject {
    @Published var settings: UserSettings {
        didSet {
            saveSettings()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "UserSettings"
    
    init() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = decodedSettings
            print("📱 Loaded settings - Current: \(settings.themeSettings.currentHandColor), Target: \(settings.themeSettings.targetHandColor)")
        } else {
            self.settings = UserSettings.default
            print("📱 Using default settings")
        }
        
        // Connect the theme settings to this manager
        self.settings.themeSettings.settingsManager = self
    }
    
    private func saveSettings() {
        print("💾 Saving user settings - Current: \(settings.themeSettings.currentHandColor), Target: \(settings.themeSettings.targetHandColor)")
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
            print("✅ Settings saved successfully")
        } else {
            print("❌ Failed to encode settings")
        }
    }
    
    func resetToDefaults() {
        settings = UserSettings.default
    }
    
    func saveSettingsNow() {
        saveSettings()
    }
}
