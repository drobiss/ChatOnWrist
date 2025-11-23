//
//  ChatOnWristWatchApp.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
import SwiftData
#if os(watchOS)
import WatchKit
#endif

@main
struct ChatOnWristWatch_Watch_AppApp: App {
    @State private var shouldStartDictation = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(shouldStartDictation: $shouldStartDictation)
                .onAppear {
                    print("Watch app starting...")
                }
                .task {
                    print("Watch app task started")
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    // Handle URL from complication tap
                    if let url = userActivity.webpageURL,
                       url.scheme == "chatonwrist" && url.host == "dictate" {
                        print("📱 Opened from complication - starting dictation")
                        shouldStartDictation = true
                    }
                }
                .onOpenURL { url in
                    // Handle deep link from complication
                    if url.scheme == "chatonwrist" && url.host == "dictate" {
                        print("📱 Opened from complication via URL - starting dictation")
                        shouldStartDictation = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ComplicationTapped"))) { notification in
                    // Handle complication tap
                    if let userInfo = notification.userInfo,
                       let action = userInfo["action"] as? String,
                       action == "dictate" {
                        print("📱 Complication tapped - starting dictation")
                        shouldStartDictation = true
                    }
                }
        }
        .modelContainer(for: [Conversation.self, Message.self])
    }
}