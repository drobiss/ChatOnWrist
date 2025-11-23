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
    
    var body: some View {
        NavigationView {
            ZStack {
                // True black background with subtle glow
                Color.black.ignoresSafeArea()
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
              let conversation = conversationStore.currentConversation,
              let deviceToken = authService.deviceToken else { return }
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        // Create user message
        let userMessage = Message(content: text, isFromUser: true)
        conversationStore.addMessage(userMessage, to: conversation)
        
        // Send to watch
        watchConnectivity.sendMessageToWatch(userMessage, conversationId: conversation.id.uuidString)
        
        // Send to backend
        isProcessing = true
        Task {
            let result = await backendService.sendTestMessage(
                message: text,
                conversation: conversation
            )
            
            await MainActor.run {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: conversation)
                    
                    // Send to watch
                    watchConnectivity.sendMessageToWatch(aiMessage, conversationId: conversation.id.uuidString)
                    
                case .failure(let error):
                    print("Error sending message: \(error.localizedDescription)")
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
