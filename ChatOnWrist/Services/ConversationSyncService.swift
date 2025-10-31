//
//  ConversationSyncService.swift
//  ChatOnWrist
//
//  Created by Codex on 26.10.2025.
//

import Foundation
import Combine
import WatchConnectivity

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
        // Listen for watch messages
        NotificationCenter.default.publisher(for: .watchMessageReceived)
            .sink { [weak self] notification in
                self?.handleWatchMessage(notification)
            }
            .store(in: &cancellables)
        
        // Listen for conversation requests from watch
        NotificationCenter.default.publisher(for: .watchConversationRequested)
            .sink { [weak self] _ in
                self?.sendAllConversationsToWatch()
            }
            .store(in: &cancellables)
        
        // Listen for conversation changes with debouncing to prevent excessive syncing
        conversationStore.$conversations
            .debounce(for: DispatchQueue.SchedulerTimeType.Stride.seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] conversations in
                self?.syncConversationsToWatch(conversations)
            }
            .store(in: &cancellables)
    }
    
    private func handleWatchMessage(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let message = userInfo["message"] as? Message,
              let conversationId = userInfo["conversationId"] as? String else { return }
        
        // Find or create conversation
        if let conversation = conversationStore.getConversation(by: UUID(uuidString: conversationId) ?? UUID()) {
            conversationStore.addMessage(message, to: conversation)
        } else {
            // Create new conversation if it doesn't exist
            let newConversation = Conversation(title: "Watch Conversation", messages: [message])
            conversationStore.conversations.insert(newConversation, at: 0)
            conversationStore.currentConversation = newConversation
        }
        
        lastSyncDate = Date()
    }
    
    private func syncConversationsToWatch(_ conversations: [Conversation]) {
        guard watchConnectivity.isWatchReachable else { 
            print("📱 Watch not reachable, skipping sync")
            return 
        }
        
        guard !conversations.isEmpty else { return }
        
        isSyncing = true
        
        // Send only recent conversations to reduce load
        let recentConversations = Array(conversations.prefix(5))
        print("📱 Syncing \(recentConversations.count) conversations to watch")
        
        for conversation in recentConversations {
            watchConnectivity.sendConversationToWatch(conversation)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }
    
    private func sendAllConversationsToWatch() {
        guard watchConnectivity.isWatchReachable else { return }
        
        for conversation in conversationStore.conversations {
            watchConnectivity.sendConversationToWatch(conversation)
        }
    }
    
    func forceSync() {
        sendAllConversationsToWatch()
    }
}
