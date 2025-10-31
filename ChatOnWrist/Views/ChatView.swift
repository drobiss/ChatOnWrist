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
                                        .tint(.white)
                                    Text("AI is thinking...")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                
                // Input Area - Glassmorphism style
                VStack(spacing: 12) {
                    // Voice Recording Button
                    HStack {
                        Button(action: toggleRecording) {
                            HStack(spacing: 8) {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text(isRecording ? "Stop Recording" : "Hold to Record")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.6)
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.2),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.4),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.8
                                        )
                                }
                            )
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                        }
                        .disabled(isLoading)
                        
                        Spacer()
                        
                        if isRecording {
                            Text("Recording...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Text Input
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $messageText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.5)
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.1),
                                                    Color.white.opacity(0.03)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.25),
                                                    Color.white.opacity(0.08)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.6
                                        )
                                }
                            )
                            .disabled(isLoading)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .opacity(0.6)
                                        
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.2),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.4),
                                                        Color.white.opacity(0.2)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.8
                                            )
                                    }
                                )
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                }
                .padding()
                .background(
                    ZStack {
                        Color.black.opacity(0.3)
                        
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .onAppear {
                // Configure navigation bar appearance for dark theme
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
            }
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
                    // Fallback: show error message
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isFromUser: false)
                    self.conversationStore.addMessage(errorMessage, to: conversation)
                }
            }
        }
    }
    
    private func sendTestMessage(message: String) async -> Result<ChatResponse, Error> {
        let result = await backendService.sendTestMessage(message: message)
        
        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
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
