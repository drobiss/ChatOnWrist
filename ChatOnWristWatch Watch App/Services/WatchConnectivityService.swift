//
//  WatchConnectivityService.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityService: NSObject, ObservableObject {
    @Published var isPhoneReachable = false
    @Published var isPhoneAppActive = false
    
    private let session = WCSession.default
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            print("Watch: WCSession is supported")
            session.delegate = self
            session.activate()
            
            // Check application context immediately for any pending messages (like logout)
            // Note: receivedApplicationContext is available after activation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let applicationContext = self.session.receivedApplicationContext
                if !applicationContext.isEmpty {
                    print("⌚️ Found application context on startup: \(applicationContext)")
                    self.handleiPhoneMessage(applicationContext)
                } else {
                    print("⌚️ No application context found on startup")
                }
            }
        } else {
            print("Watch: WCSession is not supported on this device")
        }
    }
    
    // MARK: - Send Data to iPhone
    
    func sendMessageToiPhone(_ message: Message, conversationId: String) {
        guard isPhoneReachable else { return }
        
        let data: [String: Any] = [
            "type": "message",
            "message": encodeMessage(message),
            "conversationId": conversationId
        ]
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Error sending message to iPhone: \(error.localizedDescription)")
        }
    }
    
    func requestConversationFromiPhone() {
        guard isPhoneReachable else {
            print("⌚️ Cannot request conversations: iPhone not reachable")
            return
        }
        
        print("⌚️ Sending conversation request to iPhone")
        let data: [String: Any] = [
            "type": "conversationRequest"
        ]
        
        session.sendMessage(data, replyHandler: { response in
            print("⌚️ Conversation request sent successfully, received reply: \(response)")
        }) { error in
            print("⌚️ Error requesting conversation from iPhone: \(error.localizedDescription)")
        }
    }
    
    func requestUserTokenFromiPhone() {
        guard isPhoneReachable else { return }
        
        let data: [String: Any] = [
            "type": "userTokenRequest"
        ]
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Error requesting user token from iPhone: \(error.localizedDescription)")
        }
    }
    
    func sendConversationToiPhone(_ conversation: Conversation) {
        guard isPhoneReachable else { return }
        
        let data: [String: Any] = [
            "type": "conversation",
            "conversation": encodeConversation(conversation)
        ]
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Error sending conversation to iPhone: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Receive Data from iPhone
    
    func handleiPhoneMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else {
            print("⌚️ Received message from iPhone without type")
            return
        }
        
        print("⌚️ Handling iPhone message type: \(type)")
        
        switch type {
        case "conversation":
            handleIncomingConversation(message)
        case "message":
            handleIncomingMessage(message)
        case "userToken":
            handleIncomingUserToken(message)
        case "logout":
            handleIncomingLogout(message)
        default:
            print("⌚️ Unknown message type from iPhone: \(type)")
            break
        }
    }
    
    private func handleIncomingConversation(_ message: [String: Any]) {
        guard let conversationData = message["conversation"] as? [String: Any] else { return }
        
        if let conversation = decodeConversation(conversationData) {
            NotificationCenter.default.post(
                name: .iphoneConversationReceived,
                object: nil,
                userInfo: ["conversation": conversation]
            )
        }
    }
    
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let messageData = message["message"] as? [String: Any],
              let conversationId = message["conversationId"] as? String else { return }
        
        if let decodedMessage = decodeMessage(messageData) {
            NotificationCenter.default.post(
                name: .iphoneMessageReceived,
                object: nil,
                userInfo: [
                    "message": decodedMessage,
                    "conversationId": conversationId
                ]
            )
        }
    }
    
    private func handleIncomingUserToken(_ message: [String: Any]) {
        guard let token = message["token"] as? String else {
            print("⌚️ Received userToken message but token is missing")
            return
        }
        
        print("⌚️ Received user token from iPhone: \(token.prefix(20))...")
        NotificationCenter.default.post(
            name: .iphoneUserTokenReceived,
            object: nil,
            userInfo: ["token": token]
        )
    }
    
    private func handleIncomingLogout(_ message: [String: Any]) {
        print("⌚️ Received logout signal from iPhone")
        NotificationCenter.default.post(
            name: .iphoneLogoutReceived,
            object: nil
        )
    }
    
    // MARK: - Encoding/Decoding
    
    private func encodeMessage(_ message: Message) -> [String: Any] {
        return [
            "id": message.id.uuidString,
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
    
    private func encodeConversation(_ conversation: Conversation) -> [String: Any] {
        return [
            "id": conversation.id.uuidString,
            "title": conversation.title,
            "messages": conversation.messages.map { encodeMessage($0) },
            "createdAt": conversation.createdAt.timeIntervalSince1970,
            "remoteId": conversation.remoteId ?? ""
        ]
    }
    
    private func decodeConversation(_ data: [String: Any]) -> Conversation? {
        guard let title = data["title"] as? String,
              let messagesData = data["messages"] as? [[String: Any]] else { return nil }
        
        let messages = messagesData.compactMap { decodeMessage($0) }
        let id = UUID(uuidString: data["id"] as? String ?? "") ?? UUID()
        let createdAt = Date(timeIntervalSince1970: data["createdAt"] as? TimeInterval ?? Date().timeIntervalSince1970)
        let remoteId = data["remoteId"] as? String
        
        return Conversation(
            title: title,
            messages: messages,
            remoteId: remoteId
        )
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch: WCSession activation completed with state: \(activationState.rawValue)")
        if let error = error {
            print("Watch: WCSession activation error: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.isPhoneReachable = activationState == .activated
            print("Watch: Phone reachable: \(self.isPhoneReachable)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("⌚️ Received message from iPhone: \(message["type"] as? String ?? "unknown")")
        DispatchQueue.main.async {
            self.handleiPhoneMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("⌚️ Received message with reply handler from iPhone: \(message["type"] as? String ?? "unknown")")
        DispatchQueue.main.async {
            self.handleiPhoneMessage(message)
            replyHandler(["status": "received"])
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("⌚️ Received application context from iPhone: \(applicationContext)")
        DispatchQueue.main.async {
            self.handleiPhoneMessage(applicationContext)
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        print("⌚️ Received user info from iPhone")
        DispatchQueue.main.async {
            self.handleiPhoneMessage(userInfo)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let iphoneConversationReceived = Notification.Name("iphoneConversationReceived")
    static let iphoneMessageReceived = Notification.Name("iphoneMessageReceived")
    static let iphoneUserTokenReceived = Notification.Name("iphoneUserTokenReceived")
    static let iphoneLogoutReceived = Notification.Name("iphoneLogoutReceived")
    static let conversationCreated = Notification.Name("conversationCreated")
    static let messageAdded = Notification.Name("messageAdded")
}

