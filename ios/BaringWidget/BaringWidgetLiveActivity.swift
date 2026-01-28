//
//  BaringWidgetLiveActivity.swift
//  BaringWidget
//
//  Created by 김지홍 on 1/28/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BaringWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BaringWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BaringWidgetAttributes.self) { context in
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

extension BaringWidgetAttributes {
    fileprivate static var preview: BaringWidgetAttributes {
        BaringWidgetAttributes(name: "World")
    }
}

extension BaringWidgetAttributes.ContentState {
    fileprivate static var smiley: BaringWidgetAttributes.ContentState {
        BaringWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BaringWidgetAttributes.ContentState {
         BaringWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BaringWidgetAttributes.preview) {
   BaringWidgetLiveActivity()
} contentStates: {
    BaringWidgetAttributes.ContentState.smiley
    BaringWidgetAttributes.ContentState.starEyes
}
