//
//  WatchChatView.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct WatchChatView: View {
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var speechService = SpeechService()
    @StateObject private var backendService = BackendService()
    @StateObject private var dictationService = DictationService()
    @StateObject private var presentationManager = PresentationManager.shared
    @State private var isProcessing = false
    @State private var dictatedText = ""
    @State private var isDictationActive = false
    @State private var isSheetPresented = false
    @State private var hasProcessedInitialMessage = false
    @Environment(\.dismiss) private var dismiss
    
    private let initialMessage: String?
    
    init(initialMessage: String? = nil) {
        self.initialMessage = initialMessage
    }
    
    var body: some View {
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
            
            VStack(spacing: 0) {
                // Messages area - glassmorphism design
                ScrollViewReader { proxy in
                    ScrollView {
                        if let conversation = conversationStore.currentConversation, !conversation.messages.isEmpty {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(conversation.messages) { message in
                                    WatchMessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                        } else {
                            VStack(spacing: 12) {
                                Spacer()
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "mic.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text("Tap to speak")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .opacity(0.3)
                                        
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.2),
                                                        Color.white.opacity(0.05)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.5
                                            )
                                    }
                                )
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                        }
                        
                        if isProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                                Text("Thinking...")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.4)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.8
                                        )
                                }
                            )
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                            .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 0.5)
                        }
                        
                        if speechService.isSpeaking {
                            HStack(spacing: 8) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("Speaking...")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.4)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.8
                                        )
                                }
                            )
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                            .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 0.5)
                        }
                    }
                    .onChange(of: conversationStore.currentConversation?.messages.count) { _, _ in
                        if let lastMessage = conversationStore.currentConversation?.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Bottom control bar - minimalistic
                VStack(spacing: 8) {
                    if let error = speechService.errorMessage {
                        Text(error)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    
                    Button(action: presentDictation) {
                        HStack(spacing: 8) {
                            Image(systemName: isDictationActive ? "waveform.circle.fill" : "mic.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(isDictationActive ? "Listening..." : "Tap to Speak")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            ZStack {
                                // Glass effect
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.6)
                                
                                // Minimal gradient overlay
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.15),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                // Border
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            }
                        )
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                        .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    .disabled(isProcessing || speechService.isSpeaking || isDictationActive || presentationManager.isAnyPresentationActive)
                    .buttonStyle(GlassButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        // Glass background for control bar
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)
                        
                        // Subtle gradient overlay
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.2),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            // No auto-presentations, only initialize conversation
            if conversationStore.currentConversation == nil {
                _ = conversationStore.createNewConversation()
            }
            
            if !hasProcessedInitialMessage {
                hasProcessedInitialMessage = true
                if let pending = initialMessage?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !pending.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        sendMessage(text: pending)
                    }
                }
            }
        }
        .onChange(of: isDictationActive) { _, newValue in
            // Track dictation state but don't auto-trigger
            if !newValue {
                isSheetPresented = false
            }
        }
    }
    
    private func presentDictation() {
        // Prevent if already processing, speaking, or if dictation is active
        guard !isProcessing, !speechService.isSpeaking, !isDictationActive, !isSheetPresented, presentationManager.canPresent() else {
            print("⚠️ Cannot present dictation - already active or busy or presentation active")
            return
        }
        
        isDictationActive = true
        isSheetPresented = true
        presentationManager.setPresentationActive(true)
        let suggestion = dictatedText
        
        #if os(watchOS)
        WKInterfaceDevice.current().play(.start)
        #endif
        
        dictationService.requestDictation(initialText: suggestion) { result in
            #if os(watchOS)
            WKInterfaceDevice.current().play(.stop)
            #endif
            isDictationActive = false
            isSheetPresented = false
            presentationManager.setPresentationActive(false)
            
            let trimmed = result?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            dictatedText = trimmed
            guard !trimmed.isEmpty else { return }
            
            // Small delay before sending to ensure dictation UI is fully dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                sendMessage(text: trimmed)
            }
        }
    }
    
    private func sendMessage(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if conversationStore.currentConversation == nil {
            _ = conversationStore.createNewConversation()
        }
        guard let conversation = conversationStore.currentConversation else { return }
        
        isProcessing = true
        
        let userMessage = Message(content: trimmed, isFromUser: true)
        conversationStore.addMessage(userMessage, to: conversation)
        dictatedText = ""
        
        Task {
            let conversationForRequest = conversationStore.currentConversation ?? conversation
            let result: Result<ChatResponse, BackendError>
            if let token = authService.deviceToken, !token.isEmpty {
                result = await backendService.sendMessage(
                    message: trimmed,
                    conversationId: conversation.remoteId,
                    deviceToken: token
                )
            } else {
                result = await backendService.sendTestMessage(conversation: conversationForRequest)
            }
            
            await MainActor.run {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: conversation)
                    
                    if let token = authService.deviceToken, !token.isEmpty {
                        conversationStore.updateRemoteId(response.conversationId, for: conversation.id)
                    }
                    
                    speechService.speak(response.response)
                    
                case .failure(let error):
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isFromUser: false)
                    conversationStore.addMessage(errorMessage, to: conversation)
                }
            }
        }
    }
}

struct WatchMessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 24)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.content)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                // Glass effect
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.6)
                                
                                // Minimal gradient overlay
                                RoundedRectangle(cornerRadius: 16)
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
                                
                                // Border
                                RoundedRectangle(cornerRadius: 16)
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
                        .multilineTextAlignment(.trailing)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 0.5)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.content)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                // Glass effect
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.5)
                                
                                // Minimal gradient overlay
                                RoundedRectangle(cornerRadius: 16)
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
                                
                                // Border
                                RoundedRectangle(cornerRadius: 16)
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
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .shadow(color: .white.opacity(0.03), radius: 0.5, x: 0, y: 0.25)
                }
                Spacer(minLength: 24)
            }
        }
        .padding(.horizontal, 6)
    }
}

#Preview {
    WatchChatView(initialMessage: nil)
        .environmentObject(ConversationStore())
}
