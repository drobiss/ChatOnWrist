//
//  RealtimeWebSocketService.swift
//  ChatOnWristWatch Watch App
//
//  WebSocket client for real-time voice chat with backend
//

import Foundation
import Combine

@MainActor
class RealtimeWebSocketService: ObservableObject {
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var errorMessage: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var cancellables = Set<AnyCancellable>()
    
    // Callbacks
    var onAudioResponse: ((Data) -> Void)? // Base64 decoded audio data
    var onTranscriptDelta: ((String) -> Void)?
    var onTranscriptComplete: ((String) -> Void)?
    var onResponseComplete: (() -> Void)?
    var onError: ((String) -> Void)?
    var onConversationStarted: ((String) -> Void)?
    var onConversationEnded: (() -> Void)?
    
    private let baseURL: String
    private var deviceToken: String?
    private var conversationId: String?
    
    init(baseURL: String = AppConfig.backendBaseURL) {
        self.baseURL = baseURL
    }
    
    // MARK: - Connection Management
    
    func connect(deviceToken: String, conversationId: String, conversationHistory: [[String: Any]]? = nil) {
        guard !isConnecting, !isConnected else {
            print("⚠️ WebSocket already connecting or connected")
            return
        }
        
        self.deviceToken = deviceToken
        self.conversationId = conversationId
        
        // Convert HTTP URL to WebSocket URL
        let wsURLString = baseURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        
        guard let url = URL(string: "\(wsURLString)/realtime?token=\(deviceToken)") else {
            errorMessage = "Invalid WebSocket URL"
            return
        }
        
        isConnecting = true
        errorMessage = nil
        
        // Create URLSession for WebSocket
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        urlSession = URLSession(configuration: config)
        webSocketTask = urlSession?.webSocketTask(with: url)
        
        guard let task = webSocketTask else {
            errorMessage = "Failed to create WebSocket task"
            isConnecting = false
            return
        }
        
        // Set up message handler
        receiveMessage()
        
        // Start connection
        task.resume()
        
        // Wait for connection, then send start_conversation message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sendStartConversation(conversationId: conversationId, conversationHistory: conversationHistory)
        }
        
        print("🔌 Connecting to WebSocket: \(url.absoluteString)")
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession = nil
        isConnected = false
        isConnecting = false
        print("🔌 WebSocket disconnected")
    }
    
    // MARK: - Message Sending
    
    private func sendStartConversation(conversationId: String, conversationHistory: [[String: Any]]?) {
        let message: [String: Any] = [
            "type": "start_conversation",
            "conversationId": conversationId,
            "conversationHistory": conversationHistory ?? []
        ]
        
        sendJSON(message)
    }
    
    func sendAudioChunk(_ audioData: Data) {
        // Convert audio data to base64
        let base64Audio = audioData.base64EncodedString()
        
        let message: [String: Any] = [
            "type": "audio_chunk",
            "data": base64Audio
        ]
        
        sendJSON(message)
    }
    
    func endConversation() {
        let message: [String: Any] = [
            "type": "end_conversation"
        ]
        
        sendJSON(message)
    }
    
    private func sendJSON(_ dictionary: [String: Any]) {
        guard let task = webSocketTask,
              task.state == .running else {
            print("⚠️ WebSocket not connected, cannot send message")
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to serialize JSON message")
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        task.send(message) { error in
            if let error = error {
                print("❌ Failed to send WebSocket message: \(error.localizedDescription)")
                Task { @MainActor in
                    self.errorMessage = "Send error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Message Receiving
    
    private func receiveMessage() {
        guard let task = webSocketTask else { return }
        
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                Task { @MainActor in
                    self.handleMessage(message)
                }
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error.localizedDescription)")
                Task { @MainActor in
                    self.isConnected = false
                    self.isConnecting = false
                    self.errorMessage = "Connection error: \(error.localizedDescription)"
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else {
                print("⚠️ Invalid message format")
                return
            }
            
            handleJSONMessage(type: type, json: json)
            
        case .data(let data):
            // Handle binary data (if needed)
            print("📦 Received binary data: \(data.count) bytes")
            
        @unknown default:
            print("⚠️ Unknown message type")
        }
    }
    
    private func handleJSONMessage(type: String, json: [String: Any]) {
        switch type {
        case "conversation_started":
            isConnected = true
            isConnecting = false
            if let convId = json["conversationId"] as? String {
                conversationId = convId
                onConversationStarted?(convId)
            }
            print("✅ Conversation started")
            
        case "audio_response":
            // Decode base64 audio data
            if let base64Data = json["data"] as? String,
               let audioData = Data(base64Encoded: base64Data) {
                onAudioResponse?(audioData)
            }
            
        case "transcript_delta":
            if let text = json["text"] as? String {
                onTranscriptDelta?(text)
            }
            
        case "transcript_complete":
            if let text = json["text"] as? String {
                onTranscriptComplete?(text)
            }
            
        case "response_complete":
            onResponseComplete?()
            print("✅ Response complete")
            
        case "conversation_ended":
            isConnected = false
            onConversationEnded?()
            print("🔚 Conversation ended")
            
        case "error":
            let errorMsg = json["message"] as? String ?? "Unknown error"
            errorMessage = errorMsg
            onError?(errorMsg)
            print("❌ Error: \(errorMsg)")
            
        case "speech_started":
            print("🎤 Speech started")
            
        case "speech_stopped":
            print("🎤 Speech stopped")
            
        default:
            print("📨 Unknown message type: \(type)")
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        disconnect()
    }
}


