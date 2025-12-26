//
//  RealtimeHTTPStreamService.swift
//  ChatOnWristWatch Watch App
//
//  HTTP-based real-time voice chat for watchOS (WebSocket alternative)
//  Uses HTTP chunked streaming to avoid watchOS WebSocket restrictions
//

import Foundation
import Combine

@MainActor
class RealtimeHTTPStreamService: ObservableObject {
    @Published var isConnected = false
    @Published var isStreaming = false
    @Published var errorMessage: String?
    
    // Callbacks
    var onAudioResponse: ((Data) -> Void)?
    var onTranscriptDelta: ((String) -> Void)?
    var onTranscriptComplete: ((String) -> Void)?
    var onResponseComplete: (() -> Void)?
    var onError: ((String) -> Void)?
    var onConversationStarted: ((String) -> Void)?
    var onConversationEnded: (() -> Void)?
    
    private let baseURL: String
    private var deviceToken: String?
    private var conversationId: String?
    private var uploadTask: URLSessionTask?
    private var downloadTask: URLSessionDataTask?
    private var urlSession: URLSession?
    private var audioUploadStream: InputStream?
    private var audioUploadOutputStream: OutputStream?
    
    init(baseURL: String = AppConfig.backendBaseURL) {
        self.baseURL = baseURL
    }
    
    // MARK: - Connection Management
    
    func connect(deviceToken: String, conversationId: String, conversationHistory: [[String: Any]]? = nil) {
        guard !isStreaming, !isConnected else {
            print("⚠️ HTTP stream already active")
            return
        }
        
        self.deviceToken = deviceToken
        self.conversationId = conversationId
        errorMessage = nil
        
        print("🔌 Starting HTTP streaming session...")
        
        // Start download stream first (to receive responses)
        startDownloadStream(conversationId: conversationId, conversationHistory: conversationHistory)
        
        // Wait a bit for session to be established, then start upload stream
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startUploadStream(conversationId: conversationId)
        }
    }
    
    func disconnect() {
        uploadTask?.cancel()
        downloadTask?.cancel()
        audioUploadOutputStream?.close()
        audioUploadStream?.close()
        urlSession?.invalidateAndCancel()
        
        isConnected = false
        isStreaming = false
        print("🔌 HTTP stream disconnected")
    }
    
    // MARK: - Download Stream (Receive Audio Responses)
    
    private func startDownloadStream(conversationId: String, conversationHistory: [[String: Any]]?) {
        guard let token = deviceToken else {
            errorMessage = "No device token"
            return
        }
        
        // Use ephemeral configuration for watchOS
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 600
        config.waitsForConnectivity = false
        config.allowsCellularAccess = true
        
        urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        
        // Encode conversation history as JSON
        let historyJSON = (try? JSONSerialization.data(withJSONObject: conversationHistory ?? [])) ?? Data()
        let historyBase64 = historyJSON.base64EncodedString()
        
        guard let url = URL(string: "\(baseURL)/realtime/stream?token=\(token)&conversationId=\(conversationId)&history=\(historyBase64)") else {
            errorMessage = "Invalid stream URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        print("📥 Starting download stream: \(url.absoluteString)")
        
        downloadTask = urlSession?.dataTask(with: request) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Download stream error: \(error.localizedDescription)")
                    self.errorMessage = "Stream error: \(error.localizedDescription)"
                    self.onError?(error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 Download stream response: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 200 {
                        self.isConnected = true
                        self.onConversationStarted?(conversationId)
                        print("✅ HTTP stream connected")
                    } else {
                        self.errorMessage = "Stream failed: HTTP \(httpResponse.statusCode)"
                        self.onError?("HTTP \(httpResponse.statusCode)")
                    }
                }
                
                if let data = data {
                    self.processStreamData(data)
                }
            }
        }
        
        downloadTask?.resume()
    }
    
    private func processStreamData(_ data: Data) {
        // Parse Server-Sent Events format
        guard let text = String(data: data, encoding: .utf8) else { return }
        
        let lines = text.components(separatedBy: "\n")
        var currentEvent = ""
        var currentData = ""
        
        for line in lines {
            if line.hasPrefix("event:") {
                currentEvent = String(line.dropFirst(6).trimmingCharacters(in: .whitespaces))
            } else if line.hasPrefix("data:") {
                currentData = String(line.dropFirst(5).trimmingCharacters(in: .whitespaces))
            } else if line.isEmpty && !currentEvent.isEmpty {
                handleStreamEvent(event: currentEvent, data: currentData)
                currentEvent = ""
                currentData = ""
            }
        }
    }
    
    private func handleStreamEvent(event: String, data: String) {
        switch event {
        case "conversation_started":
            isConnected = true
            onConversationStarted?(conversationId ?? "")
            print("✅ Conversation started via HTTP stream")
            
        case "audio_response":
            if let audioData = Data(base64Encoded: data) {
                onAudioResponse?(audioData)
            }
            
        case "transcript_delta":
            onTranscriptDelta?(data)
            
        case "transcript_complete":
            onTranscriptComplete?(data)
            
        case "response_complete":
            onResponseComplete?()
            print("✅ Response complete")
            
        case "conversation_ended":
            isConnected = false
            onConversationEnded?()
            print("🔚 Conversation ended")
            
        case "error":
            errorMessage = data
            onError?(data)
            print("❌ Error: \(data)")
            
        default:
            print("📨 Unknown event type: \(event)")
        }
    }
    
    // MARK: - Upload Stream (Send Audio Chunks)
    
    private func startUploadStream(conversationId: String) {
        guard let token = deviceToken else { return }
        
        guard let url = URL(string: "\(baseURL)/realtime/upload?token=\(token)&conversationId=\(conversationId)") else {
            errorMessage = "Invalid upload URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("chunked", forHTTPHeaderField: "Transfer-Encoding")
        
        // Create pipe for streaming upload
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreateBoundPair(nil, &readStream, &writeStream, 65536)
        
        guard let read = readStream?.takeRetainedValue(),
              let write = writeStream?.takeRetainedValue() else {
            errorMessage = "Failed to create upload stream"
            return
        }
        
        audioUploadStream = read as InputStream
        audioUploadOutputStream = write as OutputStream
        
        audioUploadOutputStream?.open()
        request.httpBodyStream = audioUploadStream
        
        print("📤 Starting upload stream")
        
        uploadTask = urlSession?.dataTask(with: request) { [weak self] data, response, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ Upload stream error: \(error.localizedDescription)")
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📤 Upload stream response: \(httpResponse.statusCode)")
                }
                
                self?.isStreaming = false
            }
        }
        
        uploadTask?.resume()
        isStreaming = true
    }
    
    func sendAudioChunk(_ audioData: Data) {
        guard isStreaming, let outputStream = audioUploadOutputStream else {
            print("⚠️ Cannot send audio - stream not ready")
            return
        }
        
        // Write audio data to upload stream
        audioData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard let baseAddress = bytes.baseAddress else { return }
            let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
            let written = outputStream.write(pointer, maxLength: audioData.count)
            
            if written < 0 {
                print("❌ Failed to write audio chunk: \(outputStream.streamError?.localizedDescription ?? "unknown")")
            }
        }
    }
    
    func endConversation() {
        // Close upload stream to signal end
        audioUploadOutputStream?.close()
        
        // Send end signal via separate request
        guard let token = deviceToken,
              let convId = conversationId,
              let url = URL(string: "\(baseURL)/realtime/end?token=\(token)&conversationId=\(convId)") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request).resume()
        print("🔚 Sent end conversation signal")
    }
    
    // MARK: - Cleanup
    
    deinit {
        disconnect()
    }
}

