//
//  DebugView.swift
//  ChatOnWrist
//
//  Created by Codex on 26.10.2025.
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var watchConnectivity: WatchConnectivityService
    @EnvironmentObject var conversationStore: ConversationStore
    @StateObject private var syncService = ConversationSyncService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Watch Connectivity") {
                    HStack {
                        Circle()
                            .fill(watchConnectivity.isWatchReachable ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text("Watch Reachable")
                        Spacer()
                        Text(watchConnectivity.isWatchReachable ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Circle()
                            .fill(watchConnectivity.isWatchAppInstalled ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text("Watch App Installed")
                        Spacer()
                        Text(watchConnectivity.isWatchAppInstalled ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Circle()
                            .fill(watchConnectivity.isWatchAppActive ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text("Watch App Active")
                        Spacer()
                        Text(watchConnectivity.isWatchAppActive ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Sync Status") {
                    HStack {
                        Text("Is Syncing")
                        Spacer()
                        Text(syncService.isSyncing ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text(syncService.lastSyncDate?.formatted() ?? "Never")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Conversations") {
                    HStack {
                        Text("Total Conversations")
                        Spacer()
                        Text("\(conversationStore.conversations.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Actions") {
                    Button("Force Sync") {
                        syncService.forceSync()
                    }
                    
                    Button("Clear All Conversations") {
                        conversationStore.deleteAllConversations()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Debug")
        }
    }
}

#Preview {
    DebugView()
        .environmentObject(WatchConnectivityService())
        .environmentObject(ConversationStore())
}

