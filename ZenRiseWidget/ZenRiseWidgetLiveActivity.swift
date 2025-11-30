//
//  ZenRiseWidgetLiveActivity.swift
//  ZenRiseWidget
//
//  Created by Pavan Khiani on 2025-11-30.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ZenRiseWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ZenRiseWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ZenRiseWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ZenRiseWidgetAttributes {
    fileprivate static var preview: ZenRiseWidgetAttributes {
        ZenRiseWidgetAttributes(name: "World")
    }
}

extension ZenRiseWidgetAttributes.ContentState {
    fileprivate static var smiley: ZenRiseWidgetAttributes.ContentState {
        ZenRiseWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ZenRiseWidgetAttributes.ContentState {
         ZenRiseWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ZenRiseWidgetAttributes.preview) {
   ZenRiseWidgetLiveActivity()
} contentStates: {
    ZenRiseWidgetAttributes.ContentState.smiley
    ZenRiseWidgetAttributes.ContentState.starEyes
}
