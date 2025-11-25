//
//  SimpleChatView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct SimpleChatView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var watchConnectivity: WatchConnectivityService
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var backendService = BackendService()
    
    @State private var messageText = ""
    @State private var isProcessing = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // True black background with subtle glow
                Color.black.ignoresSafeArea()
                    .onTapGesture {
                        // Dismiss keyboard when tapping background
                        isTextFieldFocused = false
                    }
                iOSPalette.backgroundGlow.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages area
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                if let conversation = conversationStore.currentConversation,
                                   !conversation.messages.isEmpty {
                                    ForEach(conversation.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                } else {
                                    emptyState
                                }
                                
                                // Status indicators
                                if isProcessing {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .tint(iOSPalette.accent)
                                        Text("Thinking…")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(iOSPalette.textSecondary)
                                    }
                                    .padding(.vertical, 12)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: conversationStore.currentConversation?.messages.count) { oldCount, newCount in
                            guard let newCount, let oldCount, newCount > oldCount,
                                  let lastMessage = conversationStore.currentConversation?.messages.last else { return }
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Input area
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .foregroundColor(iOSPalette.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(iOSPalette.glassBorder, lineWidth: 0.5)
                                    )
                            )
                            .lineLimit(1...5)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                if !messageText.isEmpty && !isProcessing {
                                    sendMessage()
                                }
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(messageText.isEmpty ? iOSPalette.textTertiary : iOSPalette.accent)
                        }
                        .disabled(messageText.isEmpty || isProcessing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.0),
                                Color.black.opacity(0.8),
                                Color.black
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .onAppear {
                // Create conversation if needed
                if conversationStore.currentConversation == nil {
                    _ = conversationStore.createNewConversation()
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "message.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(iOSPalette.accent.opacity(0.6))
            
            Text("Start a conversation")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(iOSPalette.textPrimary)
            
            Text("Type a message below to begin chatting")
                .font(.system(size: 16))
                .foregroundColor(iOSPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let conversation = conversationStore.currentConversation else {
            print("❌ Cannot send message: missing conversation or empty text")
            return
        }
        
        // Dismiss keyboard
        isTextFieldFocused = false
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        // Get the conversation ID to ensure we're working with the right one
        let conversationId = conversation.id
        
        // Capture conversation state BEFORE adding the new message
        // Get fresh copy from store to ensure we have the latest state
        guard let currentConv = conversationStore.getConversation(by: conversationId) else {
            print("❌ Conversation not found in store")
            return
        }
        
        // Create a copy of the messages array to avoid reference issues
        let conversationHistory = Array(currentConv.messages)
        
        print("📤 Preparing to send message: '\(text)'")
        print("📤 Current conversation has \(conversationHistory.count) messages in history")
        for (index, msg) in conversationHistory.enumerated() {
            print("  [\(index)] \(msg.isFromUser ? "User" : "AI"): \(msg.content.prefix(50))...")
        }
        
        // Create user message
        let userMessage = Message(content: text, isFromUser: true)
        
        // Add user message to conversation for immediate UI update
        conversationStore.addMessage(userMessage, to: conversation)
        
        // Send to watch if available
        if watchConnectivity.isWatchReachable {
            watchConnectivity.sendMessageToWatch(userMessage, conversationId: conversation.id.uuidString)
        }
        
        // Send to backend - match Watch app approach exactly
        isProcessing = true
        Task {
            // Get updated conversation from store (same as Watch app)
            // This will include the message we just added, but BackendService will handle it correctly
            let updatedConversation = await MainActor.run {
                return conversationStore.currentConversation ?? conversation
            }
            
            let result = await backendService.sendTestMessage(
                message: text,
                conversation: updatedConversation
            )
            
            await MainActor.run {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    print("✅ Received response: \(response.response.prefix(50))...")
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: conversation)
                    
                    // Send to watch if available
                    if watchConnectivity.isWatchReachable {
                        watchConnectivity.sendMessageToWatch(aiMessage, conversationId: conversation.id.uuidString)
                    }
                    
                case .failure(let error):
                    print("❌ Error sending message: \(error.localizedDescription)")
                    // Show error message to user
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isFromUser: false)
                    conversationStore.addMessage(errorMessage, to: conversation)
                }
            }
        }
    }
}

#Preview {
    SimpleChatView()
        .environmentObject(ConversationStore())
        .environmentObject(WatchConnectivityService())
}
