//
//  MainTabView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    
    var body: some View {
        TabView {
            SimpleChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .onAppear {
            if conversationStore.currentConversation == nil {
                _ = conversationStore.createNewConversation()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(ConversationStore())
        .environmentObject(AuthenticationService())
}

