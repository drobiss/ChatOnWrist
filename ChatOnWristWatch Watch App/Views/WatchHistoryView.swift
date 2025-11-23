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
    @State private var showDeleteAllConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    let onConversationSelected: (Conversation) -> Void
    
    init(onConversationSelected: @escaping (Conversation) -> Void = { _ in }) {
        self.onConversationSelected = onConversationSelected
    }
    
    var body: some View {
            ZStack {
                // True black background with subtle glow
                WatchPalette.background.ignoresSafeArea()
                WatchPalette.backgroundGlow.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if conversationStore.conversations.isEmpty {
                        emptyState
                    } else {
                        conversationList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.25),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(GlassMenuButtonStyle())
                }
            }
            .confirmationDialog(
                "Delete All Conversations?",
                isPresented: $showDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    conversationStore.deleteAllConversations()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all \(conversationStore.conversations.count) conversations. This action cannot be undone.")
            }
    }
    
    private var conversationList: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Header
                HStack {
                    Text("History")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(WatchPalette.textPrimary)
                    
                    Spacer()
                    
                    if syncService.isSyncing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(WatchPalette.accent)
                    }
                    
                    if !conversationStore.conversations.isEmpty {
                        Button(action: {
                            showDeleteAllConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Conversation rows
                ForEach(conversationStore.conversations) { conversation in
                    Button {
                        // Set conversation as current and call callback to navigate from parent
                        conversationStore.setCurrentConversation(conversation)
                        onConversationSelected(conversation)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            conversationStore.deleteConversation(conversation)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(WatchPalette.accent.opacity(0.6))
            
            Text("No conversations")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(WatchPalette.textPrimary)
            
            Text("Start a chat to see history")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(WatchPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    private func deleteConversation(at offsets: IndexSet) {
        offsets.compactMap { conversationStore.conversations[safe: $0] }
            .forEach { conversationStore.deleteConversation($0) }
    }
}

// MARK: - Conversation Row

private struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(conversation.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(WatchPalette.textPrimary)
                    .lineLimit(1)
                
                Text(conversation.messages.last?.content ?? "No messages")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(WatchPalette.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(conversation.messages.last?.timestamp.relativeTimeString ?? conversation.createdAt.relativeTimeString)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(WatchPalette.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(WatchPalette.glassBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Button Style

private struct GlassMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    WatchHistoryView()
        .environmentObject(ConversationStore())
}
