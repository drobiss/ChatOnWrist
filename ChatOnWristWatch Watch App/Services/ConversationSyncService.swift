//
//  ConversationSyncService.swift
//  ChatOnWristWatch Watch App
//
//  Created by Codex on 26.10.2025.
//

import Foundation
import Combine

@MainActor
class ConversationSyncService: ObservableObject {
    static let shared = ConversationSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let watchConnectivity: WatchConnectivityService
    private var conversationStore: ConversationStore?
    private var cancellables = Set<AnyCancellable>()
    
    // Track conversations we've synced to prevent loops
    private var recentlySyncedConversationIds = Set<UUID>()
    private var isProcessingIncomingSync = false
    
    private init() {
        self.watchConnectivity = WatchConnectivityService()
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
        
        // conversation change observer configured once store is attached
    }
    
    func configure(conversationStore: ConversationStore) {
        guard self.conversationStore !== conversationStore else { return }
        self.conversationStore = conversationStore
        
        // REMOVED: Publisher-based sync causes infinite loops
        // Instead, we rely only on notifications for explicit sync events
        
        // Listen for new conversation creation (only locally created ones)
        NotificationCenter.default.publisher(for: .conversationCreated)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let conversation = userInfo["conversation"] as? Conversation,
                      self.watchConnectivity.isPhoneReachable,
                      !self.recentlySyncedConversationIds.contains(conversation.id) else { return }
                
                // Mark as synced
                self.recentlySyncedConversationIds.insert(conversation.id)
                
                // Immediately sync new conversation to iPhone
                self.watchConnectivity.sendConversationToiPhone(conversation)
                
                // Remove from tracking after 30 seconds (longer to prevent loops)
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    self.recentlySyncedConversationIds.remove(conversation.id)
                }
            }
            .store(in: &cancellables)
        
        // Listen for new messages (only locally created ones)
        NotificationCenter.default.publisher(for: .messageAdded)
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let message = userInfo["message"] as? Message,
                      let conversationId = userInfo["conversationId"] as? String,
                      self.watchConnectivity.isPhoneReachable else { return }
                
                // Immediately sync message to iPhone
                self.watchConnectivity.sendMessageToiPhone(message, conversationId: conversationId)
            }
            .store(in: &cancellables)
    }
    
    private func handleiPhoneMessage(_ notification: Notification) {
        guard let conversationStore,
              let userInfo = notification.userInfo,
              let message = userInfo["message"] as? Message,
              let conversationId = userInfo["conversationId"] as? String else { return }
        
        // Mark that we're processing incoming sync to prevent re-syncing
        isProcessingIncomingSync = true
        
        // Find or create conversation
        if let conversation = conversationStore.getConversation(by: UUID(uuidString: conversationId) ?? UUID()) {
            conversationStore.addMessage(message, to: conversation)
        } else {
            let newConversation = Conversation(title: "iPhone Conversation", messages: [message])
            conversationStore.insertConversation(newConversation)
            
            // Mark as synced to prevent re-syncing back
            recentlySyncedConversationIds.insert(newConversation.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                self.recentlySyncedConversationIds.remove(newConversation.id)
            }
        }
        
        // Allow syncing again after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isProcessingIncomingSync = false
        }
        
        lastSyncDate = Date()
    }
    
    private func handleiPhoneConversation(_ notification: Notification) {
        guard let conversationStore,
              let userInfo = notification.userInfo,
              let conversation = userInfo["conversation"] as? Conversation else {
            print("⌚️ Failed to handle iPhone conversation: missing data")
            return
        }
        
        print("⌚️ Received conversation from iPhone: \(conversation.title) (\(conversation.messages.count) messages)")
        
        // Mark that we're processing incoming sync to prevent re-syncing
        isProcessingIncomingSync = true
        
        // Insert conversation if it doesn't exist
        conversationStore.insertConversationIfNeeded(conversation)
        
        print("⌚️ Inserted conversation. Total conversations: \(conversationStore.conversations.count)")
        
        // Mark this conversation as recently synced to prevent re-syncing it back
        recentlySyncedConversationIds.insert(conversation.id)
        
        // Remove from tracking after 30 seconds (longer to prevent loops)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.recentlySyncedConversationIds.remove(conversation.id)
        }
        
        // Allow syncing again after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isProcessingIncomingSync = false
        }
        
        lastSyncDate = Date()
    }
}