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
        ZStack {
            // Glassmorphism background
            Color.black
                .ignoresSafeArea()
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
            .accentColor(.white)
            .preferredColorScheme(.dark)
            .onAppear {
                // Configure tab bar appearance for dark theme
                let appearance = UITabBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                
                // Tab bar item appearance
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor.white.withAlphaComponent(0.6)
                ]
                
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.white
                ]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
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

