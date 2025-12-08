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
    @EnvironmentObject var watchConnectivity: WatchConnectivityService
    @StateObject private var backendService = BackendService()
    @StateObject private var realtimeAudioService = RealtimeAudioService()
    @StateObject private var realtimeWebSocketService = RealtimeWebSocketService()
    
    @State private var isProcessing = false
    @State private var hasProcessedInitialMessage = false
    @State private var useRealtimeVoice = true // Toggle between dictation and real-time voice (default: real-time)
    @State private var shouldDisconnectAfterResponse = false
    @Environment(\.dismiss) private var dismiss
    
    private let initialMessage: String?
    private let conversationToLoad: Conversation?
    
    init(initialMessage: String? = nil, conversation: Conversation? = nil) {
        self.initialMessage = initialMessage
        self.conversationToLoad = conversation
    }
    
    var body: some View {
        ZStack {
            // True black background
            WatchPalette.background.ignoresSafeArea()
            
            // Messages area - full screen
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        if let conversation = conversationStore.currentConversation, !conversation.messages.isEmpty {
                            // Sort messages by timestamp to ensure correct order
                            ForEach(conversation.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                                WatchMessageBubble(message: message)
                                    .id(message.id)
                            }
                        } else {
                            emptyState
                        }
                        
                        // Status indicators - real-time voice only
                        if isProcessing {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .tint(WatchPalette.accent)
                                    .frame(width: 16, height: 16)
                                Text("Thinking…")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(WatchPalette.textSecondary)
                            }
                            .padding(.vertical, 8)
                        }
                        if realtimeAudioService.isRecording {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .tint(WatchPalette.accent)
                                    .frame(width: 16, height: 16)
                                Text("Listening…")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(WatchPalette.textSecondary)
                            }
                            .padding(.vertical, 8)
                        }
                        if realtimeAudioService.isPlaying {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .tint(WatchPalette.accent)
                                    .frame(width: 16, height: 16)
                                Text("AI Speaking…")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(WatchPalette.textSecondary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Bottom padding for mic button
                        Spacer()
                            .frame(height: 50)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .padding(.bottom, 12)
                }
                .onChange(of: conversationStore.currentConversation?.messages.count) { oldCount, newCount in
                    guard let newCount, let oldCount, newCount > oldCount,
                          let lastMessage = conversationStore.currentConversation?.messages.last else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            // Bottom fade/blur overlay - matching top scroll behavior
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        WatchPalette.background.opacity(0.0),
                        WatchPalette.background.opacity(0.7),
                        WatchPalette.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Mic button overlay - positioned at bottom right edge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    micButtonOverlay
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    // Stop real-time voice
                    realtimeAudioService.stopRecording()
                    realtimeAudioService.stopPlayback()
                    realtimeWebSocketService.disconnect()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(WatchPalette.textSecondary)
                }
            }
        }
        .onAppear {
            // Setup real-time voice chat callbacks
            setupRealtimeVoiceChat()
            
            // If a conversation was passed in (from history), set it as current first
            if let conversation = conversationToLoad {
                conversationStore.setCurrentConversation(conversation)
                print("📱 WatchChatView opened with conversation from parameter: \(conversation.title), messages: \(conversation.messages.count)")
            }
            
            // Debug: Log current conversation state
            if let current = conversationStore.currentConversation {
                print("📱 WatchChatView opened with conversation: \(current.title), messages: \(current.messages.count)")
            } else {
                print("⚠️ WatchChatView opened with NO current conversation")
            }
            
            // Only create new conversation if we don't have one and no initial message
            // If coming from history, conversationToLoad should have been set above
            if conversationStore.currentConversation == nil {
                if initialMessage == nil {
                    // No conversation and no initial message - create new one
                    _ = conversationStore.createNewConversation()
                    print("📱 Created new conversation")
                } else {
                    // Has initial message but no conversation - create one for it
                    _ = conversationStore.createNewConversation()
                    print("📱 Created new conversation for initial message")
                }
            }
            
            // Note: Initial messages are ignored - use real-time voice chat instead
            // Real-time voice is the primary interface
        }
        .onDisappear {
            // Disconnect real-time voice chat
            realtimeWebSocketService.disconnect()
            realtimeAudioService.stopRecording()
            realtimeAudioService.stopPlayback()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(WatchPalette.accent.opacity(0.6))
            
            Text("Start a conversation")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(WatchPalette.textPrimary)
            
            Text("Tap the mic to speak")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(WatchPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.vertical, 20)
    }
    
    // MARK: - Mic Button Overlay
    
    private var micButtonOverlay: some View {
        Button(action: {
            print("🎤 Mic button tapped - toggling real-time voice")
            toggleRealtimeVoice()
        }) {
            Circle()
                .fill(WatchPalette.accent)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: realtimeAudioService.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
        .disabled(isProcessing || realtimeAudioService.isRecording)
        .buttonStyle(.plain)
        .opacity(isProcessing ? 0.5 : 1.0)
        .padding(.trailing, 4)
        .padding(.bottom, 18)
    }
    
    
    // MARK: - Real-time Voice Chat Setup
    
    private func setupRealtimeVoiceChat() {
        // Capture references for use in closures
        let store = conversationStore
        
        // Setup audio service callback
        realtimeAudioService.onAudioChunk = { [weak realtimeWebSocketService] audioData in
            realtimeWebSocketService?.sendAudioChunk(audioData)
        }
        
        // Setup WebSocket callbacks
        realtimeWebSocketService.onAudioResponse = { [weak realtimeAudioService] audioData in
            realtimeAudioService?.playAudioChunk(audioData)
        }
        
        realtimeWebSocketService.onTranscriptComplete = { text in
            Task { @MainActor in
                if let conversation = store.currentConversation, !text.isEmpty {
                    let message = Message(content: text, isFromUser: false)
                    store.addMessage(message, to: conversation)
                }
            }
        }
        
        realtimeWebSocketService.onResponseComplete = {
            print("✅ Real-time response complete")
            finalizeRealtimeSessionIfNeeded()
        }
        
        realtimeWebSocketService.onError = { error in
            print("❌ Real-time voice error: \(error)")
            shouldDisconnectAfterResponse = false
            realtimeAudioService.stopRecording()
            realtimeAudioService.stopPlayback()
            realtimeWebSocketService.disconnect()
        }
        
        realtimeWebSocketService.onConversationStarted = { conversationId in
            print("✅ Real-time conversation started: \(conversationId)")
        }
        
        realtimeWebSocketService.onConversationEnded = {
            print("🔚 Real-time conversation ended")
            finalizeRealtimeSessionIfNeeded()
        }
    }
    
    // MARK: - Real-time Voice Chat Control
    
    private func toggleRealtimeVoice() {
        print("🎤 toggleRealtimeVoice called, isRecording: \(realtimeAudioService.isRecording)")
        if realtimeAudioService.isRecording {
            stopRealtimeVoice()
        } else {
            startRealtimeVoice()
        }
    }
    
    private func startRealtimeVoice() {
        print("🎤 startRealtimeVoice called")
        shouldDisconnectAfterResponse = false
        guard let deviceToken = authService.deviceToken, !deviceToken.isEmpty else {
            print("❌ Cannot start real-time voice: device not paired")
            print("   Please sign in and pair your device first")
            return
        }
        
        print("✅ Device token found: \(deviceToken.prefix(20))...")
        
        guard let conversation = conversationStore.currentConversation else {
            print("⚠️ No conversation available, creating new one")
            _ = conversationStore.createNewConversation()
            guard let newConversation = conversationStore.currentConversation else {
                print("❌ Failed to create conversation")
                return
            }
            // Use the new conversation
            let history: [[String: String]] = []
            
            print("🔌 Connecting WebSocket for conversation: \(newConversation.id.uuidString)")
            
            // Set up callback for when WebSocket connects
            let originalOnConnected = realtimeWebSocketService.onConversationStarted
            realtimeWebSocketService.onConversationStarted = { convId in
                originalOnConnected?(convId)
                print("✅ WebSocket connected, starting recording...")
                
                // Setup playback
                realtimeAudioService.setupPlayback()
                
                // Start recording
                realtimeAudioService.startRecording()
                
                #if os(watchOS)
                WKInterfaceDevice.current().play(.start)
                #endif
            }
            
            // Set up error handler
            realtimeWebSocketService.onError = { error in
                print("❌ WebSocket error: \(error)")
                // Don't start recording on error
            }
            
            // Connect WebSocket
            realtimeWebSocketService.connect(
                deviceToken: deviceToken,
                conversationId: newConversation.id.uuidString,
                conversationHistory: history
            )
            return
        }
        
        print("✅ Conversation found: \(conversation.id.uuidString)")
        
        // Prepare conversation history
        let history = conversation.messages.map { msg in
            [
                "role": msg.isFromUser ? "user" : "assistant",
                "content": msg.content
            ]
        }
        
        print("🔌 Connecting WebSocket with \(history.count) history messages")
        
        // Set up callback for when WebSocket connects
        let originalOnConnected = realtimeWebSocketService.onConversationStarted
        realtimeWebSocketService.onConversationStarted = { convId in
            originalOnConnected?(convId)
            print("✅ WebSocket connected, starting recording...")
            
            // Setup playback
            realtimeAudioService.setupPlayback()
            
            // Start recording
            realtimeAudioService.startRecording()
            
            #if os(watchOS)
            WKInterfaceDevice.current().play(.start)
            #endif
        }
        
        // Set up error handler
        realtimeWebSocketService.onError = { error in
            print("❌ WebSocket error: \(error)")
            // Don't start recording on error
        }
        
        // Connect WebSocket
        realtimeWebSocketService.connect(
            deviceToken: deviceToken,
            conversationId: conversation.id.uuidString,
            conversationHistory: history
        )
    }
    
    private func stopRealtimeVoice() {
        shouldDisconnectAfterResponse = true
        realtimeAudioService.stopRecording()
        realtimeWebSocketService.endConversation()
        
        #if os(watchOS)
        WKInterfaceDevice.current().play(.stop)
        #endif
        
        // Fallback timeout in case we never get a completion signal
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if shouldDisconnectAfterResponse {
                print("⚠️ No response received in time, forcing disconnect")
                finalizeRealtimeSessionIfNeeded()
            }
        }
    }
    
    private func finalizeRealtimeSessionIfNeeded() {
        guard shouldDisconnectAfterResponse else { return }
        shouldDisconnectAfterResponse = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            realtimeWebSocketService.disconnect()
            realtimeAudioService.stopPlayback()
        }
    }
    
    // MARK: - Actions
    
    // Note: sendMessage is kept for initial messages, but real-time voice is the primary interface
    private func sendMessage(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Ensure we have a current conversation
        // If coming from history, it should already be set
        // If starting new, create one
        if conversationStore.currentConversation == nil {
            print("⚠️ No current conversation, creating new one")
            _ = conversationStore.createNewConversation()
        }
        
        guard let conversation = conversationStore.currentConversation else {
            print("⚠️ Error: Could not get current conversation")
            return
        }
        
        print("📤 Sending message to conversation: \(conversation.title), current messages: \(conversation.messages.count)")
        
        isProcessing = true
        
        let userMessage = Message(content: trimmed, isFromUser: true)
        conversationStore.addMessage(userMessage, to: conversation)
        
        // Sync message to iPhone
        watchConnectivity.sendMessageToiPhone(userMessage, conversationId: conversation.id.uuidString)
        
        Task {
            let result: Result<ChatResponse, BackendError>
            if let token = authService.deviceToken, !token.isEmpty {
                result = await backendService.sendMessage(
                    message: trimmed,
                    conversationId: conversation.remoteId,
                    deviceToken: token
                )
            } else {
                let updatedConversation = conversationStore.currentConversation ?? conversation
                result = await backendService.sendTestMessage(message: trimmed, conversation: updatedConversation)
            }
            
            await MainActor.run {
                isProcessing = false
                
                // Always use current conversation from store to ensure we have the latest instance
                guard let currentConversation = conversationStore.currentConversation else {
                    print("⚠️ Error: No current conversation when processing AI response")
                    return
                }
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: currentConversation)
                    
                    // Sync AI response to iPhone (just the message, not the whole conversation)
                    // The conversation will be synced when it's created, messages sync individually
                    watchConnectivity.sendMessageToiPhone(aiMessage, conversationId: currentConversation.id.uuidString)
                    
                    if let token = authService.deviceToken, !token.isEmpty {
                        conversationStore.updateRemoteId(response.conversationId, for: currentConversation.id)
                    }
                    
                    // Note: No TTS - responses come via real-time voice chat
                    
                case .failure(let error):
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isFromUser: false)
                    conversationStore.addMessage(errorMessage, to: currentConversation)
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct WatchMessageBubble: View {
    let message: Message
    @StateObject private var preferences = AppPreferences.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 20)
                
                Text(message.content)
                    .font(.system(size: preferences.fontSize, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(WatchPalette.accent)
                    )
            } else {
                Text(message.content)
                    .font(.system(size: preferences.fontSize, weight: .regular))
                    .foregroundColor(WatchPalette.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 0.5)
                            )
                    )
                
                Spacer(minLength: 20)
            }
        }
    }
}

#Preview {
    WatchChatView(initialMessage: nil)
        .environmentObject(ConversationStore())
        .environmentObject(AuthenticationService())
}
