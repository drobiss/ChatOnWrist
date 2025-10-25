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
        // Skip pairing requirement - go directly to home view
        // Watch will work with iPhone through WCSession automatically
        WatchHomeView()
            .environmentObject(conversationStore)
            .environmentObject(authService)
            .environmentObject(watchConnectivity)
    }
}

#Preview {
    ContentView()
}
