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
        return conversation
    }
    
    func addMessage(_ message: Message, to conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].messages.append(message)
            
            // Update title if it's the first message
            if conversations[index].messages.count == 1 {
                let title = String(message.content.prefix(30))
                conversations[index] = Conversation(
                    title: title,
                    messages: conversations[index].messages
                )
            }
            
            currentConversation = conversations[index]
            saveConversations()
        }
    }
    
    func getConversation(by id: UUID) -> Conversation? {
        return conversations.first { $0.id == id }
    }
    
    private func saveConversations() {
        do {
            let data = try JSONEncoder().encode(conversations)
            userDefaults.set(data, forKey: conversationsKey)
        } catch {
            print("Failed to save conversations: \(error)")
        }
    }
    
    private func loadConversations() {
        guard let data = userDefaults.data(forKey: conversationsKey) else { return }
        
        do {
            conversations = try JSONDecoder().decode([Conversation].self, from: data)
        } catch {
            print("Failed to load conversations: \(error)")
            conversations = []
        }
    }
}
