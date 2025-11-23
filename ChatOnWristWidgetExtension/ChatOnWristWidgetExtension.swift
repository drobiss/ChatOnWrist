//
//  ChatOnWristWidgetExtension.swift
//  ChatOnWristWidgetExtension
//
//  Created by David Brezina on 18.11.2025.
//

import WidgetKit
import SwiftUI

private let complicationDefaultsKey = "complication.latestText"

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: Date(), status: "Ready")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(currentEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let entry = currentEntry()
        completion(Timeline(entries: [entry], policy: .never))
    }
    
    private func currentEntry() -> ComplicationEntry {
        let text = UserDefaults.standard.string(forKey: complicationDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return ComplicationEntry(date: Date(), status: text?.isEmpty == false ? text! : "Tap to speak")
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let status: String
}

struct ChatOnWristComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: ComplicationEntry
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12, weight: .semibold))
                    Text(shortStatus)
                        .font(.system(size: 9, weight: .medium))
                        .lineLimit(1)
                }
            }
        case .accessoryRectangular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(alignment: .leading, spacing: 4) {
                    Text("ChatOnWrist")
                        .font(.system(size: 11, weight: .semibold))
                    Text(entry.status)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .accessoryInline:
            Text("Chat: \(shortStatus)")
        default:
            Text(entry.status)
        }
    }
    
    private var shortStatus: String {
        if entry.status.count > 10 {
            let idx = entry.status.index(entry.status.startIndex, offsetBy: 10)
            return entry.status[..<idx] + "…"
        }
        return entry.status
    }
}

struct ChatOnWristComplication: Widget {
    let kind = "ChatOnWristComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ChatOnWristComplicationView(entry: entry)
        }
        .configurationDisplayName("ChatOnWrist")
        .description("Glance at your latest reply.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

#Preview(as: .accessoryRectangular) {
    ChatOnWristComplication()
} timeline: {
    ComplicationEntry(date: .now, status: "Ready")
    ComplicationEntry(date: .now, status: "Hey there!")
}
