//
//  WatchConnectivityService.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityService: NSObject, ObservableObject {
    @Published var isWatchAppInstalled = false
    @Published var isWatchReachable = false
    @Published var isWatchAppActive = false
    
    private let session = WCSession.default
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Send Data to Watch
    
    func sendConversationToWatch(_ conversation: Conversation) {
        guard isWatchReachable else { return }
        
        let data: [String: Any] = [
            "type": "conversation",
            "conversation": encodeConversation(conversation)
        ]
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Error sending conversation to watch: \(error.localizedDescription)")
        }
    }
    
    func sendMessageToWatch(_ message: Message, conversationId: String) {
        guard isWatchReachable else { return }
        
        let data: [String: Any] = [
            "type": "message",
            "message": encodeMessage(message),
            "conversationId": conversationId
        ]
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Error sending message to watch: \(error.localizedDescription)")
        }
    }
    
    func sendUserTokenToWatch(_ token: String) {
        guard isWatchReachable else { return }
        
        let data: [String: Any] = [
            "type": "userToken",
            "token": token
        ]
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Error sending user token to watch: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Receive Data from Watch
    
    func handleWatchMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "message":
            handleIncomingMessage(message)
        case "conversationRequest":
            handleConversationRequest()
        case "userTokenRequest":
            handleUserTokenRequest()
        default:
            break
        }
    }
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let messageData = message["message"] as? [String: Any],
              let conversationId = message["conversationId"] as? String else { return }
        
        // Decode and process the message from watch
        if let decodedMessage = decodeMessage(messageData) {
            // Notify the conversation store
            NotificationCenter.default.post(
                name: .watchMessageReceived,
                object: nil,
                userInfo: [
                    "message": decodedMessage,
                    "conversationId": conversationId
                ]
            )
        }
    }
    
    private func handleConversationRequest() {
        // Send current conversation to watch
        NotificationCenter.default.post(name: .watchConversationRequested, object: nil)
    }
    
    private func handleUserTokenRequest() {
        // Send user token to watch
        NotificationCenter.default.post(name: .watchUserTokenRequested, object: nil)
    }
    
    // MARK: - Encoding/Decoding
    
    private func encodeConversation(_ conversation: Conversation) -> [String: Any] {
        return [
            "id": conversation.id,
            "title": conversation.title,
            "messages": conversation.messages.map { encodeMessage($0) }
        ]
    }
    
    private func encodeMessage(_ message: Message) -> [String: Any] {
        return [
            "id": message.id,
            "content": message.content,
            "isFromUser": message.isFromUser,
            "timestamp": message.timestamp.timeIntervalSince1970
        ]
    }
    
    private func decodeMessage(_ data: [String: Any]) -> Message? {
        guard let content = data["content"] as? String,
              let isFromUser = data["isFromUser"] as? Bool else { return nil }
        
        return Message(
            content: content,
            isFromUser: isFromUser
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = activationState == .activated
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchAppActive = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchAppActive = false
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
            
            // Send appropriate reply
            if let type = message["type"] as? String {
                switch type {
                case "conversationRequest":
                    // Reply with current conversation
                    replyHandler(["status": "success"])
                case "userTokenRequest":
                    // Reply with user token
                    replyHandler(["status": "success"])
                default:
                    replyHandler(["status": "received"])
                }
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let watchMessageReceived = Notification.Name("watchMessageReceived")
    static let watchConversationRequested = Notification.Name("watchConversationRequested")
    static let watchUserTokenRequested = Notification.Name("watchUserTokenRequested")
}
