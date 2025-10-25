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
        NavigationView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "applewatch")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Text("ChatOnWrist")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                // Connection Status
                HStack {
                    Circle()
                        .fill(watchConnectivity.isPhoneReachable ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(watchConnectivity.isPhoneReachable ? "iPhone Connected" : "iPhone Disconnected")
                        .font(.caption)
                        .foregroundColor(watchConnectivity.isPhoneReachable ? .green : .red)
                }
                
                Spacer()
                
                // Main Action - Quick Chat
                NavigationLink(destination: WatchChatView()) {
                    VStack(spacing: 8) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 32))
                        Text("Start Chat")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Secondary Actions
                HStack(spacing: 12) {
                    NavigationLink(destination: WatchHistoryView()) {
                        VStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.title3)
                            Text("History")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        // Quick action for voice input
                        print("Voice input tapped")
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "mic.fill")
                                .font(.title3)
                            Text("Voice")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(ConversationStore())
}

