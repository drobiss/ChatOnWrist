//
//  Conversation.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var messages: [Message]
    var remoteId: String?
    
    init(title: String = "", messages: [Message] = [], remoteId: String? = nil) {
        self.id = UUID()
        self.title = title.isEmpty ? "New Conversation" : title
        self.createdAt = Date()
        self.messages = messages
        self.remoteId = remoteId
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

