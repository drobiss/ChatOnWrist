//
//  WatchHistoryView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct WatchHistoryView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @StateObject private var syncService = ConversationSyncService.shared
    @State private var selectedConversation: Conversation?
    @State private var isDetailSheetPresented = false
    @Environment(\.dismiss) private var dismiss
    
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
            
            VStack {
                // Sync status - glassmorphism
                if syncService.isSyncing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                        Text("Syncing...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .opacity(0.4)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.8
                                )
                        }
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                    .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 0.5)
                }
                
                List {
                    if conversationStore.conversations.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            VStack(spacing: 12) {
                                Image(systemName: "clock.badge.xmark")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("No history")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button("Sync from iPhone") {
                                    syncService.requestSyncFromiPhone()
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .opacity(0.6)
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.15),
                                                        Color.white.opacity(0.05)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.3),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.8
                                            )
                                    }
                                )
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                                .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 0.5)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.3)
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.2),
                                                    Color.white.opacity(0.05)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                }
                            )
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(conversationStore.conversations) { conversation in
                            WatchConversationRow(conversation: conversation)
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    guard !isDetailSheetPresented else { return }
                                    isDetailSheetPresented = true
                                    selectedConversation = conversation
                                }
                        }
                    }
                }
                .background(Color.clear)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        conversationStore.deleteAllConversations()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        syncService.requestSyncFromiPhone()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(syncService.isSyncing ? .gray : .blue)
                    }
                    .disabled(syncService.isSyncing)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
            , alignment: .bottom
        )
        .sheet(item: $selectedConversation, onDismiss: {
            isDetailSheetPresented = false
        }) { conversation in
            WatchConversationDetailView(conversation: conversation)
        }
    }
}

struct WatchConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(conversation.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Text(conversation.createdAt, style: .relative)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Glass effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.4)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            }
        )
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        .shadow(color: .white.opacity(0.03), radius: 0.5, x: 0, y: 0.25)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct WatchConversationDetailView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    
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
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(conversation.messages) { message in
                        WatchMessageBubble(message: message)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}

#Preview {
    WatchHistoryView()
        .environmentObject(ConversationStore())
}
