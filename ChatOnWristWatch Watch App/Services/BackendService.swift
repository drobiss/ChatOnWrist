//
//  BackendService.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import Combine

class BackendService: ObservableObject {
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private let baseURL: String
    
    init(baseURL: String = AppConfig.backendBaseURL) {
        self.baseURL = baseURL
    }
    
    // MARK: - Authentication
    
    func authenticateUser(appleIDToken: String) async -> Result<UserAuthResponse, BackendError> {
        let endpoint = "/auth/apple"
        let request = AuthRequest(appleIDToken: appleIDToken)
        
        return await makeRequest(endpoint: endpoint, method: "POST", body: request)
    }
    
    func pairDevice(pairingCode: String, userToken: String) async -> Result<DevicePairResponse, BackendError> {
        let endpoint = "/device/pair"
        let request = DevicePairRequest(pairingCode: pairingCode)
        
        return await makeRequest(endpoint: endpoint, method: "POST", body: request, authToken: userToken)
    }
    
    // MARK: - Chat
    
    func sendMessage(message: String, conversationId: String?, deviceToken: String) async -> Result<ChatResponse, BackendError> {
        let endpoint = "/chat/message"
        let request = ChatRequest(message: message, conversationId: conversationId)
        
        return await makeRequest(endpoint: endpoint, method: "POST", body: request, authToken: deviceToken)
    }

    func sendTestMessage(message: String) async -> Result<ChatResponse, BackendError> {
        let endpoint = "/chat/test"
        let request = TestChatRequest(message: message)

        return await makeRequest(endpoint: endpoint, method: "POST", body: request)
    }
    
    func getConversations(deviceToken: String) async -> Result<[ConversationResponse], BackendError> {
        let endpoint = "/chat/conversations"
        
        return await makeGetRequest(endpoint: endpoint, authToken: deviceToken)
    }
    
    func getConversation(id: String, deviceToken: String) async -> Result<ConversationResponse, BackendError> {
        let endpoint = "/chat/conversations/\(id)"
        
        return await makeGetRequest(endpoint: endpoint, authToken: deviceToken)
    }
    
    // MARK: - Private Methods
    
    private func makeGetRequest<R: Codable>(
        endpoint: String,
        authToken: String
    ) async -> Result<R, BackendError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            if httpResponse.statusCode == 200 {
                let decodedResponse = try JSONDecoder().decode(R.self, from: data)
                return .success(decodedResponse)
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                return .failure(.serverError(errorResponse?.message ?? "Unknown error"))
            }
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
    
    private func makeRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil,
        authToken: String? = nil
    ) async -> Result<R, BackendError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return .failure(.encodingError)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let decodedResponse = try JSONDecoder().decode(R.self, from: data)
                return .success(decodedResponse)
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                return .failure(.serverError(errorResponse?.message ?? "Unknown error"))
            }
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }
}

// MARK: - Request/Response Models

struct AuthRequest: Codable {
    let appleIDToken: String
}

struct UserAuthResponse: Codable {
    let userToken: String
    let userId: String
    let expiresAt: String
}

struct DevicePairRequest: Codable {
    let pairingCode: String
}

struct DevicePairResponse: Codable {
    let deviceToken: String
    let deviceId: String
    let expiresAt: String
}

struct ChatRequest: Codable {
    let message: String
    let conversationId: String?
}

struct TestChatRequest: Codable {
    let message: String
}

struct ChatResponse: Codable {
    let response: String
    let conversationId: String
    let messageId: String
}

struct ConversationResponse: Codable {
    let id: String
    let title: String
    let lastMessage: String
    let createdAt: String
    let updatedAt: String
    let messages: [MessageResponse]
}

struct MessageResponse: Codable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: String
}

struct ErrorResponse: Codable {
    let message: String
    let code: String
}

struct EmptyBody: Codable {
    // Empty body for GET requests
}

// MARK: - Error Types

enum BackendError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case networkError(String)
    case serverError(String)
    case invalidResponse
    case unauthorized
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Encoding error"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .invalidResponse:
            return "Invalid response"
        case .unauthorized:
            return "Unauthorized"
        case .notFound:
            return "Not found"
        }
    }
}
