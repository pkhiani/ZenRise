//
//  ZenRiseWidget.swift
//  ZenRiseWidget
//
//  Created by Pavan Khiani on 2025-11-30.
//

import WidgetKit
import SwiftUI

/// Main widget configuration
@main
struct ZenRiseWidget: Widget {
    let kind: String = "ZenRiseWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZenRiseWidgetProvider()) { entry in
            ZenRiseWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.green.opacity(0.2), Color.mint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("ZenRise")
        .description("Track your wake-up adjustment progress")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline,
            .systemSmall
        ])
    }
}

/// Widget entry view that selects the appropriate view based on widget family
struct ZenRiseWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: ZenRiseWidgetEntry
    
    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            CircularLockscreenWidgetView(entry: entry)
        case .accessoryInline:
            InlineLockscreenWidgetView(entry: entry)
        case .systemSmall:
            SmallHomeScreenWidgetView(entry: entry)
        default:
            SmallHomeScreenWidgetView(entry: entry)
        }
    }
}

#Preview(as: .accessoryCircular) {
    ZenRiseWidget()
} timeline: {
    ZenRiseWidgetEntry(
        date: Date(),
        daysRemaining: 8,
        currentWakeUpTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        targetWakeUpTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
        nextWakeUpTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 45)) ?? Date(),
        isAlarmEnabled: true
    )
}

#Preview(as: .accessoryInline) {
    ZenRiseWidget()
} timeline: {
    ZenRiseWidgetEntry(
        date: Date(),
        daysRemaining: 8,
        currentWakeUpTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        targetWakeUpTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
        nextWakeUpTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 45)) ?? Date(),
        isAlarmEnabled: true
    )
}


#Preview(as: .systemSmall) {
    ZenRiseWidget()
} timeline: {
    ZenRiseWidgetEntry(
        date: Date(),
        daysRemaining: 8,
        currentWakeUpTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
        targetWakeUpTime: Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date(),
        nextWakeUpTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 45)) ?? Date(),
        isAlarmEnabled: true
    )
}
