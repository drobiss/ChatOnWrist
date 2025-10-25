//
//  SimpleChatView.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct SimpleChatView: View {
    @State private var messageText = ""
    @State private var messages: [String] = []
    @State private var isLoading = false
    @StateObject private var backendService = BackendService()
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages, id: \.self) { message in
                            Text(message)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
                
                // Input
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(messageText.isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("Simple Chat")
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messages.append("You: \(message)")
        messageText = ""
        isLoading = true
        
        // Call real backend API
        Task {
            let result = await backendService.sendTestMessage(message: message)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let response):
                    messages.append("AI: \(response.response)")
                case .failure(let error):
                    messages.append("AI: Error - \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    SimpleChatView()
}
