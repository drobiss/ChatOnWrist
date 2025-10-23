//
//  WatchHistoryView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct WatchHistoryView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @State private var selectedConversation: Conversation?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(conversationStore.conversations) { conversation in
                    WatchConversationRow(conversation: conversation)
                        .onTapGesture {
                            selectedConversation = conversation
                        }
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedConversation) { conversation in
                WatchConversationDetailView(conversation: conversation)
            }
        }
    }
}

struct WatchConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Text(conversation.createdAt, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct WatchConversationDetailView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(conversation.messages) { message in
                        WatchMessageBubble(message: message)
                    }
                }
                .padding()
            }
            .navigationTitle(conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WatchHistoryView()
        .environmentObject(ConversationStore())
}
