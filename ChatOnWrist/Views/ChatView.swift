//
//  ChatView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var conversationStore = ConversationStore()
    @StateObject private var speechService = SpeechService()
    @StateObject private var backendService = BackendService()
    
    @State private var messageText = ""
    @State private var isRecording = false
    @State private var currentConversationId: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if let currentConversation = conversationStore.currentConversation {
                            ForEach(currentConversation.messages, id: \.id) { message in
                                MessageBubble(
                                    message: message.content,
                                    isFromUser: message.isFromUser,
                                    timestamp: message.timestamp
                                )
                            }
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Input Area
                VStack(spacing: 12) {
                    // Voice Recording Button
                    HStack {
                        Button(action: toggleRecording) {
                            HStack {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                Text(isRecording ? "Stop Recording" : "Hold to Record")
                            }
                            .foregroundColor(isRecording ? .red : .blue)
                        }
                        .disabled(isLoading)
                        
                        Spacer()
                        
                        if isRecording {
                            Text("Recording...")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Text Input
                    HStack {
                        TextField("Type a message...", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isLoading)
                        
                        Button("Send") {
                            sendMessage()
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadConversations()
        }
        .onChange(of: speechService.recognizedText) { _, newText in
            if !newText.isEmpty {
                messageText = newText
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
        speechService.startRecording()
    }
    
    private func stopRecording() {
        speechService.stopRecording()
        isRecording = false
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messageText = ""
        isLoading = true
        
        // Create or get current conversation
        let conversation = conversationStore.currentConversation ?? conversationStore.createNewConversation()
        
        // Add user message
        let userMessage = Message(content: message, isFromUser: true)
        conversationStore.addMessage(userMessage, to: conversation)
        
        // Send to backend test endpoint
        Task {
            let result = await sendTestMessage(message: message)
            
            await MainActor.run {
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    self.conversationStore.addMessage(aiMessage, to: conversation)
                    self.currentConversationId = response.conversationId
                case .failure(let error):
                    print("Error sending message: \(error)")
                }
            }
        }
    }
    
    private func sendTestMessage(message: String) async -> Result<ChatResponse, Error> {
        guard let url = URL(string: AppConfig.backendBaseURL + "/test-chat") else {
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
    
    private func loadConversations() {
        // Load conversations from backend
        Task {
            // Implementation would load from BackendService
        }
    }
}

#Preview {
    ChatView()
}
