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
        
        // Send to backend test endpoint
        Task {
            let result = await sendTestMessage(message: recognizedText)
            
            await MainActor.run {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: self.currentConversation!)
                    
                    // Auto-play TTS
                    speechService.speak(response.response)
                    
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
    
    private func sendTestMessage(message: String) async -> Result<ChatResponse, Error> {
        guard let url = URL(string: AppConfig.backendBaseURL + "/chat/test") else {
            return .failure(NSError(domain: "Invalid URL", code: 0))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["message": message]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .failure(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure(NSError(domain: "Server error", code: 0))
            }
            
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            return .success(chatResponse)
        } catch {
            return .failure(error)
        }
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
}
