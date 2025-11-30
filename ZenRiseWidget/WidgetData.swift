import Foundation

/// Shared data model for widget
/// This struct is stored in App Group UserDefaults to share data between the app and widget
struct WidgetData: Codable {
    let currentWakeUpTime: Date
    let targetWakeUpTime: Date
    let isAlarmEnabled: Bool
    let startDate: Date?
    let daysRemaining: Int
    let nextWakeUpTime: Date
    
    static let appGroupIdentifier = "group.com.zenrise.shared"
    static let widgetDataKey = "widgetData"
    
    /// Save widget data to shared UserDefaults
    func save() {
        guard let userDefaults = UserDefaults(suiteName: WidgetData.appGroupIdentifier) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        if let encoded = try? JSONEncoder().encode(self) {
            userDefaults.set(encoded, forKey: WidgetData.widgetDataKey)
            print("✅ Widget data saved successfully")
        }
    }
    
    /// Load widget data from shared UserDefaults
    static func load() -> WidgetData? {
        guard let userDefaults = UserDefaults(suiteName: WidgetData.appGroupIdentifier) else {
            print("❌ Failed to access App Group UserDefaults")
            return nil
        }
        
        guard let data = userDefaults.data(forKey: WidgetData.widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            print("⚠️ No widget data found")
            return nil
        }
        
        return decoded
    }
}
