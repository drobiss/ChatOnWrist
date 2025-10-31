//
//  ConversationSyncService.swift
//  ChatOnWristWatch Watch App
//
//  Created by Codex on 26.10.2025.
//

import Foundation
import Combine

class ConversationSyncService: ObservableObject {
    static let shared = ConversationSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let watchConnectivity: WatchConnectivityService
    private let conversationStore: ConversationStore
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.watchConnectivity = WatchConnectivityService()
        self.conversationStore = ConversationStore()
        
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Listen for iPhone messages
        NotificationCenter.default.publisher(for: .iphoneMessageReceived)
            .sink { [weak self] notification in
                self?.handleiPhoneMessage(notification)
            }
            .store(in: &cancellables)
        
        // Listen for iPhone conversations
        NotificationCenter.default.publisher(for: .iphoneConversationReceived)
            .sink { [weak self] notification in
                self?.handleiPhoneConversation(notification)
            }
            .store(in: &cancellables)
        
        // Listen for conversation changes with debouncing to prevent excessive syncing
        conversationStore.$conversations
            .debounce(for: DispatchQueue.SchedulerTimeType.Stride.seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] conversations in
                self?.syncConversationsToiPhone(conversations)
            }
            .store(in: &cancellables)
    }
    
    private func handleiPhoneMessage(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let message = userInfo["message"] as? Message,
              let conversationId = userInfo["conversationId"] as? String else { return }
        
        // Find or create conversation
        if let conversation = conversationStore.getConversation(by: UUID(uuidString: conversationId) ?? UUID()) {
            conversationStore.addMessage(message, to: conversation)
        } else {
            // Create new conversation if it doesn't exist
            let newConversation = Conversation(title: "iPhone Conversation", messages: [message])
            conversationStore.conversations.insert(newConversation, at: 0)
            conversationStore.currentConversation = newConversation
        }
        
        lastSyncDate = Date()
    }
    
    private func handleiPhoneConversation(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let conversation = userInfo["conversation"] as? Conversation else { return }
        
        // Check if conversation already exists
        if conversationStore.getConversation(by: conversation.id) == nil {
            conversationStore.conversations.insert(conversation, at: 0)
            conversationStore.currentConversation = conversation
        }
        
        lastSyncDate = Date()
    }
    
    private func syncConversationsToiPhone(_ conversations: [Conversation]) {
        guard watchConnectivity.isPhoneReachable else { 
            print("⌚ Phone not reachable, skipping sync")
            return 
        }
        
        guard !conversations.isEmpty else { return }
        
        isSyncing = true
        
        // Send only recent conversations to reduce load
        let recentConversations = Array(conversations.prefix(5))
        print("⌚ Syncing \(recentConversations.count) conversations to iPhone")
        
        for conversation in recentConversations {
            watchConnectivity.sendConversationToiPhone(conversation)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }
    
    func requestSyncFromiPhone() {
        guard watchConnectivity.isPhoneReachable else { return }
        watchConnectivity.requestConversationFromiPhone()
    }
    
    func forceSync() {
        requestSyncFromiPhone()
    }
}
