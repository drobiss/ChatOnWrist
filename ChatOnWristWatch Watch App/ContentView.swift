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
        if authService.isAuthenticated {
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
                    // Configure auth service to request token from iPhone if needed
                    authService.configure(watchConnectivity: watchConnectivity)
                }
        } else {
            // Show message when not authenticated
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
                
                Text("Not Signed In")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Sign in on iPhone")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .task {
                // Request token from iPhone
                authService.configure(watchConnectivity: watchConnectivity)
            }
        }
    }
}

#Preview {
    ContentView(shouldStartDictation: .constant(false))
}