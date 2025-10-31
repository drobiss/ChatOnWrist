//
//  ChatOnWristWatchApp.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

@main
struct ChatOnWristWatch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("Watch app starting...")
                }
                .task {
                    print("Watch app task started")
                }
        }
    }
}
