//
//  ContentView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var conversationStore = ConversationStore()
    @StateObject private var authService = AuthenticationService()
    @StateObject private var watchConnectivity = WatchConnectivityService()
    @StateObject private var syncService = ConversationSyncService.shared
    
    @Binding var shouldStartDictation: Bool
    
    var body: some View {
        // Skip pairing requirement - go directly to home view
        // Watch will work with iPhone through WCSession automatically
        WatchHomeView(shouldStartDictation: $shouldStartDictation)
            .environmentObject(conversationStore)
            .environmentObject(authService)
            .environmentObject(watchConnectivity)
            .environmentObject(syncService)
            .task {
                conversationStore.attach(modelContext: modelContext)
                syncService.configure(conversationStore: conversationStore)
            }
    }
}

#Preview {
    ContentView(shouldStartDictation: .constant(false))
}