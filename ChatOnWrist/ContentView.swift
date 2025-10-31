//
//  ContentView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var conversationStore = ConversationStore()
    @StateObject private var watchConnectivity = WatchConnectivityService()
    @StateObject private var syncService = ConversationSyncService.shared
    
    var body: some View {
        if authService.isAuthenticated {
            MainTabView()
                .environmentObject(authService)
                .environmentObject(conversationStore)
                .environmentObject(watchConnectivity)
                .environmentObject(syncService)
        } else {
            LoginView()
                .environmentObject(authService)
        }
    }
}

#Preview {
    ContentView()
}
