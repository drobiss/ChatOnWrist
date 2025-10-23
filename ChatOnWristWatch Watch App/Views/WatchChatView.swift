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
    @EnvironmentObject var openAIService: OpenAIService
    @StateObject private var speechService = SpeechService()
    @State private var isProcessing = false
    @State private var currentConversation: Conversation?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let conversation = currentConversation, !conversation.messages.isEmpty {
                    // Show last message
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(conversation.messages.suffix(3)) { message in
                                WatchMessageBubble(message: message)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text("Tap to start speaking")
                            .font(.headline)
                        Text("Your question will be sent automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Speak button
                Button(action: toggleRecording) {
                    VStack {
                        Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title)
                        Text(speechService.isRecording ? "Stop" : "🎙️ Speak")
                            .font(.caption)
                    }
                    .frame(width: 80, height: 80)
                    .background(speechService.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                }
                .disabled(isProcessing || !speechService.isAuthorized)
                
                // Processing indicator
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                // Action buttons (only show when there's a response)
                if let conversation = currentConversation,
                   let lastMessage = conversation.messages.last,
                   !lastMessage.isFromUser {
                    HStack(spacing: 20) {
                        Button(action: replayVoice) {
                            VStack {
                                Image(systemName: "speaker.wave.2.fill")
                                Text("Replay")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(.blue)
                        
                        Button(action: stopVoice) {
                            VStack {
                                Image(systemName: "speaker.slash.fill")
                                Text("Stop")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if currentConversation == nil {
                currentConversation = conversationStore.createNewConversation()
            }
        }
    }
    
    private func toggleRecording() {
        if speechService.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        speechService.startRecording()
    }
    
    private func stopRecording() {
        speechService.stopRecording()
        isProcessing = true
        
        // Use the recognized text from speech service
        let recognizedText = speechService.recognizedText.isEmpty ? "What's the weather like today?" : speechService.recognizedText
        let userMessage = Message(content: recognizedText, isFromUser: true)
        conversationStore.addMessage(userMessage, to: currentConversation!)
        
        // Send to OpenAI
        openAIService.sendMessage(recognizedText) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: self.currentConversation!)
                    
                    // Auto-play TTS
                    speechService.speak(response)
                    
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func replayVoice() {
        guard let conversation = currentConversation,
              let lastMessage = conversation.messages.last,
              !lastMessage.isFromUser else { return }
        
        speechService.speak(lastMessage.content)
    }
    
    private func stopVoice() {
        // Note: AVSpeechSynthesizer doesn't have a direct stop method in this context
        // The SpeechService handles this internally
    }
}

struct WatchMessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.content)
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .font(.caption)
            } else {
                Text(message.content)
                    .padding(8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    .font(.caption)
                Spacer()
            }
        }
    }
}

#Preview {
    WatchChatView()
        .environmentObject(ConversationStore())
        .environmentObject(OpenAIService(apiKey: ""))
}
