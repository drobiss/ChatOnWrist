//
//  BackendTestService.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import Combine

class BackendTestService: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var lastTestTime: Date?
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private let baseURL: String
    
    enum ConnectionStatus: Equatable {
        case unknown
        case connecting
        case connected
        case failed(String)
        
        var description: String {
            switch self {
            case .unknown:
                return "Not tested"
            case .connecting:
                return "Testing connection..."
            case .connected:
                return "Connected"
            case .failed(let error):
                return "Failed: \(error)"
            }
        }
    }
    
    init(baseURL: String = AppConfig.backendBaseURL) {
        self.baseURL = baseURL
    }
    
    func testConnection() async {
        await MainActor.run {
            self.connectionStatus = .connecting
            self.errorMessage = nil
        }
        
        // Test basic connectivity
        guard let url = URL(string: baseURL + "/health") else {
            await MainActor.run {
                self.connectionStatus = .failed("Invalid URL")
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        do {
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                await MainActor.run {
                    self.lastTestTime = Date()
                    if httpResponse.statusCode == 200 {
                        self.connectionStatus = .connected
                    } else {
                        self.connectionStatus = .failed("HTTP \(httpResponse.statusCode)")
                    }
                }
            } else {
                await MainActor.run {
                    self.connectionStatus = .failed("Invalid response")
                }
            }
        } catch {
            await MainActor.run {
                self.connectionStatus = .failed(error.localizedDescription)
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func testAuthentication() async -> Bool {
        // This would test the authentication endpoint
        // For now, just return true if basic connection works
        switch connectionStatus {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    func testChatEndpoint() async -> Bool {
        // This would test the chat endpoint
        // For now, just return true if basic connection works
        switch connectionStatus {
        case .connected:
            return true
        default:
            return false
        }
    }
}
