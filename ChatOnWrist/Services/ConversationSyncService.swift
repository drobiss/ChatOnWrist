//
//  ConversationSyncService.swift
//  ChatOnWrist
//
//  Created by Codex on 26.10.2025.
//

import Foundation
import Combine
import WatchConnectivity

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
                      self.watchConnectivity.isWatchReachable,
                      !self.recentlySyncedConversationIds.contains(conversation.id) else { return }
                
                // Mark as synced
                self.recentlySyncedConversationIds.insert(conversation.id)
                
                // Immediately sync new conversation to Watch
                self.watchConnectivity.sendConversationToWatch(conversation)
                
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
                      self.watchConnectivity.isWatchReachable else { return }
                
                // Immediately sync message to Watch
                self.watchConnectivity.sendMessageToWatch(message, conversationId: conversationId)
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Listen for watch messages
        NotificationCenter.default.publisher(for: .watchMessageReceived)
            .sink { [weak self] notification in
                self?.handleWatchMessage(notification)
            }
            .store(in: &cancellables)
        
        // Listen for watch conversations
        NotificationCenter.default.publisher(for: .watchConversationReceived)
            .sink { [weak self] notification in
                self?.handleWatchConversation(notification)
            }
            .store(in: &cancellables)
        
        // Listen for conversation requests from watch
        NotificationCenter.default.publisher(for: .watchConversationRequested)
            .sink { [weak self] _ in
                print("📱 Watch requested all conversations - sending them now")
                self?.sendAllConversationsToWatch()
            }
            .store(in: &cancellables)
    }
    
    private func handleWatchMessage(_ notification: Notification) {
        guard let conversationStore,
              let userInfo = notification.userInfo,
              let message = userInfo["message"] as? Message,
              let conversationId = userInfo["conversationId"] as? String else { return }
        
        // Mark that we're processing incoming sync to prevent re-syncing
        isProcessingIncomingSync = true
        
        // Find or create conversation
        if let conversationIdUUID = UUID(uuidString: conversationId),
           let conversation = conversationStore.getConversation(by: conversationIdUUID) {
            conversationStore.addMessage(message, to: conversation)
        } else {
            let newConversation = Conversation(title: "Watch Conversation", messages: [message])
            conversationStore.insertConversationIfNeeded(newConversation)
            
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
    
    private func handleWatchConversation(_ notification: Notification) {
        guard let conversationStore,
              let userInfo = notification.userInfo,
              let conversation = userInfo["conversation"] as? Conversation else { return }
        
        // Mark that we're processing incoming sync to prevent re-syncing
        isProcessingIncomingSync = true
        
        // Insert conversation if it doesn't exist
        conversationStore.insertConversationIfNeeded(conversation)
        
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
    
    private func sendAllConversationsToWatch() {
        guard let conversationStore,
              watchConnectivity.isWatchReachable else {
            print("📱 Cannot send conversations: Watch not reachable or store not configured")
            return
        }
        
        // Filter out recently synced conversations to prevent loops
        let conversationsToSync = conversationStore.conversations.filter { conversation in
            !recentlySyncedConversationIds.contains(conversation.id)
        }
        
        print("📱 Sending \(conversationsToSync.count) conversations to Watch")
        
        for conversation in conversationsToSync {
            print("📱 Sending conversation: \(conversation.title) (\(conversation.messages.count) messages)")
            watchConnectivity.sendConversationToWatch(conversation)
        }
        
        lastSyncDate = Date()
    }
    
    func forceSync() {
        guard !isSyncing else { return }
        isSyncing = true
        
        // Clear recently synced IDs to allow full sync
        recentlySyncedConversationIds.removeAll()
        
        // Send all conversations to watch
        sendAllConversationsToWatch()
        
        // Reset syncing flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSyncing = false
        }
    }
}
