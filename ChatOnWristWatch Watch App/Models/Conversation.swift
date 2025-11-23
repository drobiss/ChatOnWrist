//
//  Conversation.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import SwiftData

@Model
final class Conversation: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var remoteId: String?
    @Relationship(deleteRule: .cascade, inverse: \Message.conversation) var messages: [Message]
    
    init(title: String = "", messages: [Message] = [], remoteId: String? = nil) {
        self.id = UUID()
        self.title = title.isEmpty ? "New Conversation" : title
        self.createdAt = Date()
        self.messages = messages
        self.remoteId = remoteId
    }
}

@Model
final class Message: Identifiable {
    @Attribute(.unique) var id: UUID
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var conversation: Conversation?
    
    init(content: String, isFromUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.conversation = nil
    }
}
