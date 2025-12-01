//
//  ContentView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var conversationStore = ConversationStore()
    @StateObject private var watchConnectivity = WatchConnectivityService()
    @StateObject private var syncService = ConversationSyncService.shared
    
    var body: some View {
        ZStack {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environmentObject(conversationStore)
                    .environmentObject(watchConnectivity)
                    .environmentObject(syncService)
                    .onAppear {
                        syncService.configure(conversationStore: conversationStore)
                        // Send token to Watch if available
                        if let token = authService.userAccessToken {
                            print("📱 MainTabView appeared - sending token to Watch")
                            watchConnectivity.sendUserTokenToWatch(token)
                        }
                        
                        // Send all conversations to Watch on startup to sync history
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if watchConnectivity.isWatchReachable {
                                print("📱 Sending all conversations to Watch on startup")
                                syncService.forceSync()
                            } else {
                                print("📱 Watch not reachable yet, will sync when Watch requests")
                            }
                        }
                    }
                    .transition(.opacity)
            } else {
                LoginView()
                    .environmentObject(authService)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authService.isAuthenticated)
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            print("📱 ContentView: Authentication state changed to \(isAuthenticated)")
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchUserTokenRequested)) { _ in
            // Watch requested token - send it if we have one
            if let token = authService.userAccessToken {
                print("📱 Watch requested token - sending it: \(token.prefix(20))...")
                watchConnectivity.sendUserTokenToWatch(token)
            } else {
                print("📱 Watch requested token but user is not authenticated")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userAuthenticated)) { _ in
            // User just authenticated - send token to Watch immediately
            // Use a small delay to ensure token is set, then retry if needed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let token = authService.userAccessToken {
                    print("📱 User authenticated - sending token to Watch: \(token.prefix(20))...")
                    watchConnectivity.sendUserTokenToWatch(token)
                    
                    // Retry after 1 second if Watch might not be ready yet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if watchConnectivity.isWatchReachable {
                            print("📱 Retrying token send to Watch (Watch is now reachable)")
                            watchConnectivity.sendUserTokenToWatch(token)
                        }
                    }
                } else {
                    print("📱 User authenticated but token not available yet")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userLoggedOut)) { _ in
            // User logged out - notify Watch
            print("📱 User logged out - notifying Watch")
            watchConnectivity.sendLogoutToWatch()
        }
    }
}

#Preview {
    ContentView()
}