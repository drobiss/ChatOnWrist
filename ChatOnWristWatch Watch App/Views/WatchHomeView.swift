//
//  WatchHomeView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @StateObject private var watchConnectivity = WatchConnectivityService()
    
    var body: some View {
        VStack(spacing: 12) {
            // Header - Compact for Watch
            VStack(spacing: 4) {
                Image(systemName: "applewatch")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("ChatOnWrist")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            // Connection Status - Compact
            HStack {
                Circle()
                    .fill(watchConnectivity.isPhoneReachable ? .green : .red)
                    .frame(width: 6, height: 6)
                Text(watchConnectivity.isPhoneReachable ? "Connected" : "Disconnected")
                    .font(.caption2)
                    .foregroundColor(watchConnectivity.isPhoneReachable ? .green : .red)
            }
            
            Spacer()
            
            // Main Action - Optimized for Watch
            NavigationLink(destination: WatchChatView()) {
                VStack(spacing: 6) {
                    Image(systemName: "message.circle.fill")
                        .font(.title2)
                    Text("Chat")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Secondary Actions - Compact
            HStack(spacing: 8) {
                NavigationLink(destination: WatchHistoryView()) {
                    VStack(spacing: 2) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("History")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    // Quick action for voice input
                    print("Voice input tapped")
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                        Text("Voice")
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.green.opacity(0.3))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(8)
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(ConversationStore())
}

