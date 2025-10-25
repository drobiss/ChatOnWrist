//
//  WatchChatView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
import AVFoundation

struct WatchChatView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @StateObject private var speechService = SpeechService()
    @StateObject private var backendService = BackendService()
    @State private var isProcessing = false
    @State private var currentConversation: Conversation?
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Messages - Compact for Watch
            if let conversation = currentConversation, !conversation.messages.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(conversation.messages.suffix(2)) { message in
                            WatchMessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 120)
            } else {
                // Empty state - Compact
                VStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Tap to speak")
                        .font(.headline)
                }
                .padding()
            }
            
            Spacer()
            
            // Speak button - Simplified
            Button(action: toggleRecording) {
                VStack(spacing: 4) {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.title2)
                    Text(isRecording ? "Stop" : "Speak")
                        .font(.caption)
                }
                .frame(width: 60, height: 60)
                .background(isRecording ? Color.red : Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
            }
            .disabled(isProcessing)
            
            // Processing indicator
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(8)
        .onAppear {
            if currentConversation == nil {
                currentConversation = conversationStore.createNewConversation()
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        // Simplified - just show recording state
        print("Recording started")
    }
    
    private func stopRecording() {
        isRecording = false
        isProcessing = true
        
        // Simplified - use a default message for now to avoid audio issues
        let userMessage = Message(content: "Hello, how are you?", isFromUser: true)
        conversationStore.addMessage(userMessage, to: currentConversation!)
        
        // Send via backend test endpoint
        Task {
            let result = await backendService.sendTestMessage(message: "Hello, how are you?")
            
            await MainActor.run {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: self.currentConversation!)
                    
                case .failure(let error):
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isFromUser: false)
                    conversationStore.addMessage(errorMessage, to: self.currentConversation!)
                }
            }
        }
    }
}

struct WatchMessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.content)
                    .padding(6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .font(.caption2)
            } else {
                Text(message.content)
                    .padding(6)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(6)
                    .font(.caption2)
                Spacer()
            }
        }
    }
}

#Preview {
    WatchChatView()
        .environmentObject(ConversationStore())
}
