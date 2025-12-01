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
            print("WCSession is supported")
            session.delegate = self
            session.activate()
        } else {
            print("WCSession is not supported on this device")
        }
    }
    
    // MARK: - Send Data to Watch
    
    func sendConversationToWatch(_ conversation: Conversation) {
        guard isWatchReachable else { 
            print("📱 Watch not reachable, skipping conversation send")
            return 
        }
        
        let data: [String: Any] = [
            "type": "conversation",
            "conversation": encodeConversation(conversation)
        ]
        
        session.sendMessage(data, replyHandler: { response in
            print("📱 Conversation sent to watch successfully")
        }) { error in
            print("❌ Error sending conversation to watch: \(error.localizedDescription)")
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
        let data: [String: Any] = [
            "type": "userToken",
            "token": token
        ]
        
        // Try to send via message (requires Watch to be reachable)
        if isWatchReachable {
            print("📱 Sending user token to Watch via message (Watch is reachable)")
            session.sendMessage(data, replyHandler: { response in
                print("📱 Token sent to Watch successfully")
            }) { error in
                print("❌ Error sending user token to watch via message: \(error.localizedDescription)")
                // Fallback: try application context
                self.sendTokenViaApplicationContext(token)
            }
        } else {
            print("📱 Watch not immediately reachable, using application context")
            // Use application context as fallback (works even if Watch app isn't running)
            sendTokenViaApplicationContext(token)
        }
    }
    
    private func sendTokenViaApplicationContext(_ token: String) {
        let data: [String: Any] = [
            "type": "userToken",
            "token": token
        ]
        
        do {
            try session.updateApplicationContext(data)
            print("📱 Token sent to Watch via application context")
        } catch {
            print("❌ Error sending token via application context: \(error.localizedDescription)")
        }
    }
    
    func sendLogoutToWatch() {
        let data: [String: Any] = [
            "type": "logout"
        ]
        
        // Always use application context for logout so it persists even if Watch isn't running
        do {
            try session.updateApplicationContext(data)
            print("📱 Logout sent to Watch via application context")
        } catch {
            print("❌ Error sending logout via application context: \(error.localizedDescription)")
        }
        
        // Also try sending via message if Watch is reachable
        if isWatchReachable {
            session.sendMessage(data, replyHandler: nil) { error in
                print("❌ Error sending logout message to watch: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Receive Data from Watch
    
    func handleWatchMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else {
            print("📱 Received message from Watch without type")
            return
        }
        
        print("📱 Handling Watch message type: \(type)")
        
        switch type {
        case "message":
            handleIncomingMessage(message)
        case "conversation":
            handleIncomingConversation(message)
        case "conversationRequest":
            handleConversationRequest()
        case "userTokenRequest":
            handleUserTokenRequest()
        default:
            print("📱 Unknown message type from Watch: \(type)")
            break
        }
    }
    
    private func handleIncomingConversation(_ message: [String: Any]) {
        guard let conversationData = message["conversation"] as? [String: Any] else { return }
        
        if let conversation = decodeConversation(conversationData) {
            NotificationCenter.default.post(
                name: .watchConversationReceived,
                object: nil,
                userInfo: ["conversation": conversation]
            )
        }
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
        print("📱 Watch requested user token - posting notification")
        NotificationCenter.default.post(name: .watchUserTokenRequested, object: nil)
    }
    
    // MARK: - Encoding/Decoding
    
    private func encodeConversation(_ conversation: Conversation) -> [String: Any] {
        return [
            "id": conversation.id.uuidString,
            "title": conversation.title,
            "messages": conversation.messages.map { encodeMessage($0) },
            "createdAt": conversation.createdAt.timeIntervalSince1970,
            "remoteId": conversation.remoteId ?? ""
        ]
    }
    
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
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activation completed with state: \(activationState.rawValue)")
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.isWatchAppInstalled = activationState == .activated
            self.isWatchReachable = session.isReachable
            print("Watch app installed: \(self.isWatchAppInstalled)")
            print("Watch reachable: \(self.isWatchReachable)")
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
        print("Watch reachability changed: \(session.isReachable)")
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📱 Received message from Watch")
        DispatchQueue.main.async {
            self.handleWatchMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("📱 Received message with reply handler from Watch")
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
                    print("📱 Replying to Watch token request")
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
    static let watchConversationReceived = Notification.Name("watchConversationReceived")
    static let watchConversationRequested = Notification.Name("watchConversationRequested")
    static let watchUserTokenRequested = Notification.Name("watchUserTokenRequested")
    static let conversationCreated = Notification.Name("conversationCreated")
    static let messageAdded = Notification.Name("messageAdded")
    static let userAuthenticated = Notification.Name("userAuthenticated")
    static let userLoggedOut = Notification.Name("userLoggedOut")
}
