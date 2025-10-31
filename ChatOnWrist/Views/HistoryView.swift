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
    @EnvironmentObject var watchConnectivity: WatchConnectivityService
    @StateObject private var syncService = ConversationSyncService.shared
    @State private var selectedConversation: Conversation?
    @State private var showingSyncStatus = false
    
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
                    // Connection status bar - glassmorphism style
                    HStack {
                        Circle()
                            .fill(watchConnectivity.isWatchReachable ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(watchConnectivity.isWatchReachable ? "Watch Connected" : "Watch Offline")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if syncService.isSyncing {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(.white)
                            Text("Syncing...")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .opacity(0.3)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.05),
                                            Color.white.opacity(0.02)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                    )
                    .padding(.horizontal)
                
                List {
                    ForEach(conversationStore.conversations) { conversation in
                        ConversationRow(conversation: conversation)
                            .onTapGesture {
                                selectedConversation = conversation
                            }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                }
                .refreshable {
                    syncService.forceSync()
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            conversationStore.deleteAllConversations()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            syncService.forceSync()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(syncService.isSyncing ? .gray : .blue)
                        }
                        .disabled(syncService.isSyncing)
                    }
                }
            }
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
            .sheet(item: $selectedConversation) { conversation in
                ConversationDetailView(conversation: conversation)
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(conversation.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Text(conversation.createdAt, style: .relative)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct ConversationDetailView: View {
    let conversation: Conversation
    @EnvironmentObject var conversationStore: ConversationStore
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var backendService = BackendService()
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
        
        // Send via backend test endpoint for now
        Task {
            let conversationForRequest = conversationStore.currentConversation ?? conversation
            let result = await sendTestMessage(conversation: conversationForRequest)
            
            await MainActor.run {
                isSending = false
                
                switch result {
                case .success(let response):
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: conversation)
                    
                    // Speak the response
                    speakText(response.response)
                    
                case .failure(let error):
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isFromUser: false)
                    conversationStore.addMessage(errorMessage, to: conversation)
                }
            }
        }
    }
    
    private func sendTestMessage(conversation: Conversation) async -> Result<ChatResponse, Error> {
        let result = await backendService.sendTestMessage(conversation: conversation)
        
        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        
        // Use the most natural-sounding English voice
        let naturalVoiceIdentifiers = [
            "com.apple.voice.enhanced.en-US.Samantha",     // Siri Female (Enhanced) - Most natural (Physical only)
            "com.apple.voice.enhanced.en-US.Alex",         // Alex (Enhanced) - Very natural (Physical only)
            "com.apple.voice.enhanced.en-GB.Daniel",       // British Male (Enhanced) (Physical only)
            "com.apple.voice.enhanced.en-AU.Karen",        // Australian Female (Enhanced) (Physical only)
            "com.apple.voice.compact.en-US.Samantha",      // Samantha (Compact) - Good fallback
            "com.apple.voice.compact.en-US.Alex",          // Alex (Compact) - Good fallback
            "com.apple.voice.compact.en-GB.Daniel",        // Daniel (Compact) - British
            "com.apple.voice.compact.en-AU.Karen"          // Karen (Compact) - Australian
        ]
        
        // Fallback voices for simulator and older devices
        let fallbackVoiceNames = [
            "Samantha",    // Most natural standard voice
            "Alex",        // Good male voice
            "Daniel",      // British accent
            "Karen",       // Australian accent
            "Tessa",       // South African accent
            "Moira"        // Irish accent
        ]
        
        // Try to find the most natural voice
        var selectedVoice: AVSpeechSynthesisVoice?
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Try each natural voice identifier in order of preference
        for voiceIdentifier in naturalVoiceIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
                selectedVoice = voice
                break
            }
        }
        
        // Try to find voices by name (for simulator compatibility)
        if selectedVoice == nil {
            for voiceName in fallbackVoiceNames {
                if let voice = availableVoices.first(where: { 
                    $0.name == voiceName && $0.language.hasPrefix("en") 
                }) {
                    selectedVoice = voice
                    break
                }
            }
        }
        
        // Fallback to any enhanced English voice (if available on physical device)
        if selectedVoice == nil {
            let enhancedEnglishVoices = availableVoices.filter { voice in
                voice.language.hasPrefix("en") && voice.name.contains("Enhanced")
            }
            selectedVoice = enhancedEnglishVoices.first
        }
        
        // Try to find the best standard English voice
        if selectedVoice == nil {
            let standardEnglishVoices = availableVoices.filter { voice in
                voice.language.hasPrefix("en") && !voice.name.contains("Enhanced") && 
                !voice.name.contains("Bad News") && !voice.name.contains("Bahh") &&
                !voice.name.contains("Bells") && !voice.name.contains("Boing") &&
                !voice.name.contains("Bubbles") && !voice.name.contains("Cellos") &&
                !voice.name.contains("Wobble") && !voice.name.contains("Fred") &&
                !voice.name.contains("Good News") && !voice.name.contains("Jester") &&
                !voice.name.contains("Junior") && !voice.name.contains("Kathy") &&
                !voice.name.contains("Organ") && !voice.name.contains("Superstar") &&
                !voice.name.contains("Ralph") && !voice.name.contains("Trinoids") &&
                !voice.name.contains("Whisper") && !voice.name.contains("Zarvox")
            }
            selectedVoice = standardEnglishVoices.first
        }
        
        // Final fallback to any English voice
        if selectedVoice == nil {
            selectedVoice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.voice = selectedVoice
        
        // Optimized speech parameters for natural sound
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.05
        utterance.volume = 0.95
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.25
        
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    HistoryView()
        .environmentObject(ConversationStore())
}
