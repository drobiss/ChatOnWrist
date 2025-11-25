//
//  MainTabView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                TabView {
                    SimpleChatView()
                        .environmentObject(authService)
                        .tabItem {
                            Label("Chat", systemImage: "message.fill")
                        }
                    
                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                .preferredColorScheme(.dark)
                .onAppear {
                    // Configure tab bar appearance
                    let appearance = UITabBarAppearance()
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = .black
                    appearance.shadowColor = .clear
                    
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            } else {
                // This shouldn't be visible, but acts as a fallback
                Color.clear
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                print("📱 MainTabView: Authentication changed to false, view should dismiss")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(ConversationStore())
        .environmentObject(AuthenticationService())
}
