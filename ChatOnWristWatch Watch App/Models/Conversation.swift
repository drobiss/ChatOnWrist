//
//  Conversation.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation

struct Conversation: Identifiable, Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    var messages: [Message]
    
    init(title: String = "", messages: [Message] = []) {
        self.id = UUID()
        self.title = title.isEmpty ? "New Conversation" : title
        self.createdAt = Date()
        self.messages = messages
    }
}

struct Message: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(content: String, isFromUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
}


