import WidgetKit
import SwiftUI

/// Timeline entry for the widget
struct ZenRiseWidgetEntry: TimelineEntry {
    let date: Date
    let daysRemaining: Int
    let currentWakeUpTime: Date
    let targetWakeUpTime: Date
    let nextWakeUpTime: Date
    let isAlarmEnabled: Bool
}

/// Timeline provider for the widget
struct ZenRiseWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ZenRiseWidgetEntry {
        ZenRiseWidgetEntry(
            date: Date(),
            daysRemaining: 8,
            currentWakeUpTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
            targetWakeUpTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
            nextWakeUpTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 45)) ?? Date(),
            isAlarmEnabled: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ZenRiseWidgetEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ZenRiseWidgetEntry>) -> Void) {
        let entry = createEntry()
        
        // Update widget every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func createEntry() -> ZenRiseWidgetEntry {
        // Load data from shared UserDefaults
        if let widgetData = WidgetData.load() {
            return ZenRiseWidgetEntry(
                date: Date(),
                daysRemaining: widgetData.daysRemaining,
                currentWakeUpTime: widgetData.currentWakeUpTime,
                targetWakeUpTime: widgetData.targetWakeUpTime,
                nextWakeUpTime: widgetData.nextWakeUpTime,
                isAlarmEnabled: widgetData.isAlarmEnabled
            )
        } else {
            // Return placeholder data if no data is available
            return ZenRiseWidgetEntry(
                date: Date(),
                daysRemaining: 0,
                currentWakeUpTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
                targetWakeUpTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
                nextWakeUpTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
                isAlarmEnabled: false
            )
        }
    }
}
