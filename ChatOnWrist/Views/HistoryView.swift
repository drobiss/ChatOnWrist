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
    @EnvironmentObject var syncService: ConversationSyncService
    @State private var selectedConversation: Conversation?
    @State private var showingSyncStatus = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // True black background with subtle glow
                iOSPalette.background.ignoresSafeArea()
                iOSPalette.backgroundGlow.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if conversationStore.conversations.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(conversationStore.conversations) { conversation in
                                Button {
                                    selectedConversation = conversation
                                } label: {
                                    ConversationRow(conversation: conversation)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        conversationStore.deleteConversation(conversation)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                            }
                            .onDelete(perform: deleteConversations)
                        }
                        .id(conversationStore.conversations.count) // Force refresh when conversations change
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .refreshable {
                    syncService.forceSync()
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if syncService.isSyncing {
                            ProgressView()
                                .tint(iOSPalette.accent)
                        }
                        
                        Button(action: {
                            syncService.forceSync()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(iOSPalette.accent)
                        }
                        .disabled(syncService.isSyncing)
                        
                        if !conversationStore.conversations.isEmpty {
                            Button(action: {
                                conversationStore.deleteAllConversations()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                configureNavigationBar()
            }
            .sheet(item: $selectedConversation) { conversation in
                ConversationDetailView(conversation: conversation)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(iOSPalette.accent.opacity(0.6))
            
            Text("No conversations")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(iOSPalette.textPrimary)
            
            Text("Start a chat to see history")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(iOSPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        let conversationsToDelete = offsets.compactMap { index -> Conversation? in
            guard index < conversationStore.conversations.count else { return nil }
            return conversationStore.conversations[index]
        }
        
        for conversation in conversationsToDelete {
            conversationStore.deleteConversation(conversation)
        }
    }
    
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(conversation.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iOSPalette.textPrimary)
                    .lineLimit(1)
                
                Text(conversation.messages.sorted(by: { $0.timestamp < $1.timestamp }).last?.content ?? "No messages")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(iOSPalette.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(conversation.messages.sorted(by: { $0.timestamp < $1.timestamp }).last?.timestamp.relativeTimeString ?? conversation.createdAt.relativeTimeString)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(iOSPalette.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(iOSPalette.glassBorder, lineWidth: 0.5)
                )
        )
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
    @Environment(\.dismiss) private var dismiss
    
    // Get the current conversation from store to ensure we see updates
    private var currentConversation: Conversation? {
        conversationStore.getConversation(by: conversation.id) ?? conversation
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // True black background with subtle glow
                iOSPalette.background.ignoresSafeArea()
                iOSPalette.backgroundGlow.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Sort messages by timestamp to ensure correct order
                            // Use currentConversation from store to see real-time updates
                            if let currentConv = currentConversation {
                                ForEach(currentConv.messages.sorted(by: { $0.timestamp < $1.timestamp })) { message in
                                    MessageBubble(message: message)
                                }
                            }
                            
                            if isSending {
                                HStack {
                                    ProgressView()
                                        .tint(iOSPalette.accent)
                                    Text("Thinking…")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(iOSPalette.textSecondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                    
                    // Input area
                    HStack(spacing: 12) {
                        TextField("Continue conversation...", text: $messageText)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(iOSPalette.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(iOSPalette.glassBorder, lineWidth: 0.5)
                                    )
                            )
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(iOSPalette.accent)
                                )
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        iOSPalette.background
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationTitle(currentConversation?.title ?? conversation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(iOSPalette.accent)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                configureNavigationBar()
            }
        }
    }
    
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Get the current conversation from store to ensure we're updating the right one
        guard let currentConv = currentConversation else { return }
        
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let userMessage = Message(content: trimmedText, isFromUser: true)
        conversationStore.addMessage(userMessage, to: currentConv)
        
        isSending = true
        messageText = ""
        
        // Send via backend test endpoint for now
        Task {
            // Get the updated conversation from store
            guard let updatedConv = conversationStore.getConversation(by: currentConv.id) else { return }
            let result = await backendService.sendTestMessage(message: trimmedText, conversation: updatedConv)
            
            await MainActor.run {
                isSending = false
                
                switch result {
                case .success(let response):
                    // Get the latest conversation from store
                    guard let latestConv = conversationStore.getConversation(by: currentConv.id) else { return }
                    let aiMessage = Message(content: response.response, isFromUser: false)
                    conversationStore.addMessage(aiMessage, to: latestConv)
                    
                    // Speak the response
                    speakText(response.response)
                    
                case .failure(let error):
                    // Get the latest conversation from store
                    guard let latestConv = conversationStore.getConversation(by: currentConv.id) else { return }
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isFromUser: false)
                    conversationStore.addMessage(errorMessage, to: latestConv)
                }
            }
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
