//
//  ContentView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var conversationStore = ConversationStore()
    @StateObject private var authService = AuthenticationService()
    @StateObject private var watchConnectivity = WatchConnectivityService()
    
    var body: some View {
        if authService.deviceToken != nil {
            WatchHomeView()
                .environmentObject(conversationStore)
                .environmentObject(authService)
                .environmentObject(watchConnectivity)
        } else {
            WatchPairingView()
                .environmentObject(authService)
        }
    }
}

#Preview {
    ContentView()
}
