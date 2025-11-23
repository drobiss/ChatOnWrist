//
//  ConversationStore.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import Combine

class ConversationStore: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    
    private let userDefaults = UserDefaults.standard
    private let conversationsKey = "savedConversations"
    
    init() {
        loadConversations()
    }
    
    func createNewConversation() -> Conversation {
        let conversation = Conversation()
        conversations.insert(conversation, at: 0)
        currentConversation = conversation
        saveConversations()
        
        // Sync new conversation to Watch
        NotificationCenter.default.post(
            name: .conversationCreated,
            object: nil,
            userInfo: ["conversation": conversation]
        )
        
        return conversation
    }
    
    func addMessage(_ message: Message, to conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            // Check if message already exists (by content and timestamp to avoid duplicates)
            let messageSignature = "\(message.content)-\(message.timestamp.timeIntervalSince1970)"
            let existingSignatures = Set(conversations[index].messages.map { "\($0.content)-\($0.timestamp.timeIntervalSince1970)" })
            
            if !existingSignatures.contains(messageSignature) {
                // Update the existing conversation
                conversations[index].messages.append(message)
                
                // Sort messages by timestamp
                conversations[index].messages.sort { $0.timestamp < $1.timestamp }
                
                // Update title if it's the first message
                if conversations[index].messages.count == 1 {
                    let title = String(message.content.prefix(30))
                    conversations[index].title = title.isEmpty ? "New Conversation" : title
                }
                
                // Update current conversation reference
                currentConversation = conversations[index]
                print("Added message: \(message.content), total messages: \(conversations[index].messages.count)")
                saveConversations()
            } else {
                print("Message already exists, skipping: \(message.content)")
            }
            
            // Sync message to Watch
            NotificationCenter.default.post(
                name: .messageAdded,
                object: nil,
                userInfo: [
                    "message": message,
                    "conversationId": conversation.id.uuidString
                ]
            )
        } else {
            print("Error: Conversation not found")
        }
    }
    
    func updateRemoteId(_ remoteId: String, for conversationId: UUID) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].remoteId = remoteId
            currentConversation = conversations[index]
            saveConversations()
        }
    }
    
    func getConversation(by id: UUID) -> Conversation? {
        return conversations.first { $0.id == id }
    }
    
    func insertConversationIfNeeded(_ conversation: Conversation) {
        if let existingIndex = conversations.firstIndex(where: { $0.id == conversation.id }) {
            // Conversation exists - merge messages if needed
            let existingMessageIds = Set(conversations[existingIndex].messages.map { $0.id })
            for message in conversation.messages {
                if !existingMessageIds.contains(message.id) {
                    conversations[existingIndex].messages.append(message)
                }
            }
            
            // Sort messages by timestamp
            conversations[existingIndex].messages.sort { $0.timestamp < $1.timestamp }
            
            // Update title if incoming has a better one
            if conversation.title != "New Conversation" && conversations[existingIndex].title == "New Conversation" {
                conversations[existingIndex].title = conversation.title
            }
            
            // Update remoteId if needed
            if let remoteId = conversation.remoteId {
                conversations[existingIndex].remoteId = remoteId
            }
            
            saveConversations()
        } else {
            // New conversation - insert it
            conversations.insert(conversation, at: 0)
            saveConversations()
        }
    }
    
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        if currentConversation?.id == conversation.id {
            currentConversation = conversations.first
        }
        saveConversations()
    }
    
    func deleteAllConversations() {
        conversations.removeAll()
        currentConversation = nil
        saveConversations()
    }
    
    // MARK: - Persistence
    
    func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            userDefaults.set(encoded, forKey: conversationsKey)
        }
    }
    
    private func loadConversations() {
        if let data = userDefaults.data(forKey: conversationsKey),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }
}
