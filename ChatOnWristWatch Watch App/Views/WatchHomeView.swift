//
//  WatchHomeView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status indicator
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("Connected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Main buttons
                VStack(spacing: 16) {
                    NavigationLink(destination: WatchChatView()) {
                        VStack {
                            Image(systemName: "message.fill")
                                .font(.title2)
                            Text("Chat")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: WatchHistoryView()) {
                        VStack {
                            Image(systemName: "clock.fill")
                                .font(.title2)
                            Text("History")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("ChatOnWrist")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(ConversationStore())
}

