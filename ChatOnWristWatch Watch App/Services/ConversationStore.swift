//
//  ConversationStore.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class ConversationStore: ObservableObject {
    @Published private(set) var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    
    private var modelContext: ModelContext?
    private let legacyKey = "savedConversations"
    private var isInitialLoad = true
    
    func attach(modelContext: ModelContext) {
        guard self.modelContext !== modelContext else { return }
        self.modelContext = modelContext
        loadConversations()
        isInitialLoad = false
    }
    
    // MARK: - CRUD
    
    func createNewConversation() -> Conversation {
        guard let modelContext else { fatalError("ModelContext not attached") }
        let conversation = Conversation()
        modelContext.insert(conversation)
        saveContext()
        
        // Update array efficiently - insert at beginning (newest first)
        conversations.insert(conversation, at: 0)
        currentConversation = conversation
        
        // Sync new conversation to iPhone
        NotificationCenter.default.post(
            name: .conversationCreated,
            object: nil,
            userInfo: ["conversation": conversation]
        )
        
        return conversation
    }
    
    func insertConversation(_ conversation: Conversation) {
        guard let modelContext else { return }
        
        // Check if already exists
        if getConversation(by: conversation.id) == nil {
            modelContext.insert(conversation)
            saveContext()
            
            // Insert at correct position (maintain sorted order)
            insertConversationInSortedOrder(conversation)
        }
        
        currentConversation = conversation
    }
    
    func addMessage(_ message: Message, to conversation: Conversation) {
        guard modelContext != nil else { return }
        
        // Always use the conversation instance from our array to ensure SwiftData tracking works correctly
        guard let existingConversation = getConversation(by: conversation.id) else {
            print("⚠️ Warning: Conversation \(conversation.id) not found in array when adding message")
            // Fallback: use the passed conversation
            message.conversation = conversation
            conversation.messages.append(message)
            currentConversation = conversation
            saveContext()
            return
        }
        
        // Check if message already exists (by content and timestamp to avoid duplicates)
        let messageSignature = "\(message.content)-\(message.timestamp.timeIntervalSince1970)"
        let existingSignatures = Set(existingConversation.messages.map { "\($0.content)-\($0.timestamp.timeIntervalSince1970)" })
        
        if !existingSignatures.contains(messageSignature) {
            // Use the existing instance from our array
            message.conversation = existingConversation
            existingConversation.messages.append(message)
            
            // Sort messages by timestamp
            existingConversation.messages.sort { $0.timestamp < $1.timestamp }
            
            // Update title if this is the first message
            if existingConversation.messages.count == 1 {
                let title = String(message.content.prefix(30))
                existingConversation.title = title.isEmpty ? "New Conversation" : title
            }
        } else {
            print("⚠️ Message already exists, skipping: \(message.content)")
            return
        }
        
        // Always update current conversation reference if it's the same conversation
        // This ensures we're always using the latest SwiftData instance
        if currentConversation?.id == existingConversation.id || currentConversation == nil {
            currentConversation = existingConversation
        }
        
        // Move conversation to top when a message is added (last used)
        moveConversationToTop(existingConversation)
        
        saveContext()
        
        // Sync message to iPhone
        NotificationCenter.default.post(
            name: .messageAdded,
            object: nil,
            userInfo: [
                "message": message,
                "conversationId": existingConversation.id.uuidString
            ]
        )
        
#if os(watchOS)
        ComplicationReloader.updateLatest(text: message.content)
#endif
        // No need to reload - SwiftData tracks changes automatically
    }
    
    func updateRemoteId(_ remoteId: String, for conversationId: UUID) {
        guard let conversation = conversations.first(where: { $0.id == conversationId }) else { return }
        conversation.remoteId = remoteId
        currentConversation = conversation
        saveContext()
        // No need to reload - changes are tracked automatically
    }
    
    func getConversation(by id: UUID) -> Conversation? {
        conversations.first { $0.id == id }
    }
    
    func setCurrentConversation(_ conversation: Conversation) {
        // Refresh from array to ensure we have latest SwiftData instance
        if let refreshed = conversations.first(where: { $0.id == conversation.id }) {
            currentConversation = refreshed
        } else {
            currentConversation = conversation
        }
    }
    
    func insertConversationIfNeeded(_ conversation: Conversation) {
        guard let modelContext else { return }
        
        if let existing = getConversation(by: conversation.id) {
            // Conversation exists - merge messages if needed
            // Only add messages that don't already exist
            let existingMessageIds = Set(existing.messages.map { $0.id })
            for message in conversation.messages {
                if !existingMessageIds.contains(message.id) {
                    message.conversation = existing
                    existing.messages.append(message)
                }
            }
            
            // Update title if incoming has a better one
            if conversation.title != "New Conversation" && existing.title == "New Conversation" {
                existing.title = conversation.title
            }
            
            saveContext()
            
            // Only update currentConversation if it's the same conversation or if there's no current conversation
            // This prevents switching away from the conversation the user is viewing
            if currentConversation == nil || currentConversation?.id == existing.id {
                currentConversation = existing
            }
        } else {
            // New conversation - insert it
            modelContext.insert(conversation)
            saveContext()
            insertConversationInSortedOrder(conversation)
            
            // Only set as current if there's no current conversation
            // This prevents switching away from the conversation the user is viewing
            if currentConversation == nil {
                if let refreshed = conversations.first(where: { $0.id == conversation.id }) {
                    currentConversation = refreshed
                }
            }
        }
    }
    
    func deleteConversation(_ conversation: Conversation) {
        guard let modelContext else { return }
        
        modelContext.delete(conversation)
        
        // Update array efficiently
        conversations.removeAll { $0.id == conversation.id }
        
        if currentConversation?.id == conversation.id {
            currentConversation = conversations.first
        }
        
        saveContext()
    }
    
    func deleteAllConversations() {
        guard let modelContext else { return }
        
        conversations.forEach { modelContext.delete($0) }
        conversations.removeAll()
        currentConversation = nil
        
        saveContext()
    }
    
    /// Refresh conversations from SwiftData (call only when needed, e.g., after sync)
    func refreshConversations() {
        loadConversations()
    }
    
    // MARK: - Persistence helpers
    
    /// Load conversations from SwiftData (only call when necessary)
    private func loadConversations() {
        guard let modelContext else { return }
        
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let fetched = try modelContext.fetch(descriptor)
            conversations = fetched
            
            // Refresh current conversation reference
            if let current = currentConversation,
               let refreshed = conversations.first(where: { $0.id == current.id }) {
                currentConversation = refreshed
            } else if !isInitialLoad {
                // Only auto-select first if not initial load (preserve user selection)
                currentConversation = conversations.first
            }
        } catch {
            print("❌ Failed to load conversations: \(error.localizedDescription)")
            conversations = []
        }
    }
    
    /// Insert conversation maintaining sorted order (newest first)
    private func insertConversationInSortedOrder(_ conversation: Conversation) {
        let insertIndex = conversations.firstIndex { $0.createdAt < conversation.createdAt } ?? conversations.endIndex
        conversations.insert(conversation, at: insertIndex)
    }
    
    /// Move conversation to the top of the list (when last used)
    private func moveConversationToTop(_ conversation: Conversation) {
        guard let index = conversations.firstIndex(where: { $0.id == conversation.id }) else { return }
        
        // Only move if it's not already at the top
        if index > 0 {
            conversations.remove(at: index)
            conversations.insert(conversation, at: 0)
        }
    }
    
    private func saveContext() {
        guard let modelContext else { return }
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save context: \(error.localizedDescription)")
        }
    }
}


