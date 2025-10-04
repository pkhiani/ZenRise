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
        } else {
            self.settings = UserSettings.default
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    func resetToDefaults() {
        settings = UserSettings.default
    }
}
