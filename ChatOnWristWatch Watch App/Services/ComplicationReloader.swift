//
//  ComplicationReloader.swift
//  ChatOnWristWatch Watch App
//

#if os(watchOS)
import ClockKit

enum ComplicationReloader {
    private static let defaultsKey = "complication.latestText"
    
    static func updateLatest(text: String) {
        UserDefaults.standard.set(text, forKey: defaultsKey)
        reloadAll()
    }
    
    static func reloadAll() {
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach { server.reloadTimeline(for: $0) }
    }
}
#endif
