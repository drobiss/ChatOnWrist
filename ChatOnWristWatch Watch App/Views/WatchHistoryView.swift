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
            
            VStack(spacing: 16) {
                historyHeader
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if conversationStore.conversations.isEmpty {
                            EmptyHistoryState(onSync: syncService.requestSyncFromiPhone)
                                .padding(.top, 24)
                        } else {
                            ForEach(conversationStore.conversations) { conversation in
                                Button {
                                    guard !isDetailSheetPresented else { return }
                                    selectedConversation = conversation
                                    isDetailSheetPresented = true
                                } label: {
                                    WatchConversationCard(conversation: conversation)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
                
                actionBar
            }
            .padding(.top, 12)
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
        .sheet(item: $selectedConversation, onDismiss: {
            isDetailSheetPresented = false
        }) { conversation in
            WatchConversationDetailView(conversation: conversation)
        }
    }
    
    private var historyHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Conversation History")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer(minLength: 8)
                if syncService.isSyncing {
                    SyncPillView(text: "Syncing…", systemImage: "arrow.triangle.2.circlepath")
                } else if let lastSync = syncService.lastSyncDate {
                    SyncPillView(
                        text: lastSync.relativeTimeString,
                        systemImage: "clock.arrow.2.circlepath"
                    )
                }
            }
            
            HStack(spacing: 8) {
                Label("\(conversationStore.conversations.count) chats", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                
                if let latestDate = mostRecentConversationDate() {
                    Text("Updated \(latestDate.relativeTimeString)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                conversationStore.deleteAllConversations()
            } label: {
                Label("Clear", systemImage: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.red.opacity(0.35))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.red.opacity(0.55), lineWidth: 0.6)
                            )
                    )
            }
            .buttonStyle(.plain)
            
            Button {
                syncService.requestSyncFromiPhone()
            } label: {
                Label(syncService.isSyncing ? "Syncing…" : "Sync", systemImage: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.black.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(syncService.isSyncing ? 0.35 : 0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 0.6)
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(syncService.isSyncing)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
    
    private func mostRecentConversationDate() -> Date? {
        conversationStore.conversations
            .compactMap { conversation in
                conversation.messages.last?.timestamp
                    ?? conversation.messages.first?.timestamp
                    ?? conversation.createdAt
            }
            .sorted(by: >)
            .first
    }
}

private struct SyncPillView: View {
    var text: String
    var systemImage: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .medium))
            Text(text)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.45)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                )
        )
        .foregroundColor(.white.opacity(0.8))
    }
}

private struct EmptyHistoryState: View {
    var onSync: () -> Void
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "clock.fill")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.65))
                .padding(10)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.35)
                )
            
            Text("No conversations yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Start a new chat or sync your latest conversations from the iPhone app.")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            Button(action: onSync) {
                Label("Sync from iPhone", systemImage: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.black.opacity(0.85))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 0.6)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.35)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.6)
                )
        )
    }
}

struct WatchConversationCard: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let lastMessage = conversation.messages.last {
                        Text(lastMessage.content)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                
                Spacer(minLength: 6)
                
                if let lastTimestamp = conversation.messages.last?.timestamp {
                    Text(lastTimestamp.relativeTimeString)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            HStack(spacing: 8) {
                Label("\(conversation.messages.count) msgs", systemImage: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                
                if let firstMessage = conversation.messages.first {
                    Text("Started " + firstMessage.timestamp.relativeTimeString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                .shadow(color: .white.opacity(0.05), radius: 2, x: 0, y: 1)
        )
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
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(conversation.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let lastMessage = conversation.messages.last {
                        Text("Last reply \(lastMessage.timestamp.relativeTimeString)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(conversation.messages) { message in
                            WatchMessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
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

// MARK: - Helpers

private extension Date {
    var relativeTimeString: String {
        RelativeDateTimeFormatter.watchFormatter.localizedString(for: self, relativeTo: Date())
    }
}

private extension RelativeDateTimeFormatter {
    static let watchFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}
