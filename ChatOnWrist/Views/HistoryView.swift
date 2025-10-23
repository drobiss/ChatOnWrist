//
//  HistoryView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
import AVFoundation

struct HistoryView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @State private var selectedConversation: Conversation?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(conversationStore.conversations) { conversation in
                    ConversationRow(conversation: conversation)
                        .onTapGesture {
                            selectedConversation = conversation
                        }
                }
            }
            .navigationTitle("History")
            .sheet(item: $selectedConversation) { conversation in
                ConversationDetailView(conversation: conversation)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)
            
            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Text(conversation.createdAt, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ConversationDetailView: View {
    let conversation: Conversation
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var openAIService: OpenAIService
    @State private var messageText = ""
    @State private var isSending = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(
                                message: message.content,
                                isFromUser: message.isFromUser,
                                timestamp: message.timestamp
                            )
                        }
                    }
                    .padding()
                }
                
                // Input area
                HStack {
                    TextField("Continue conversation...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.isEmpty || isSending)
                }
                .padding()
            }
            .navigationTitle(conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss sheet
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: messageText, isFromUser: true)
        conversationStore.addMessage(userMessage, to: conversation)
        
        isSending = true
        let currentText = messageText
        messageText = ""
        
        openAIService.sendMessage(currentText) { result in
            DispatchQueue.main.async {
                isSending = false
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: conversation)
                    
                    // Speak the response
                    speakText(response)
                    
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    HistoryView()
        .environmentObject(ConversationStore())
}
