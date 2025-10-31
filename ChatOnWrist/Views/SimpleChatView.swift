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
    @StateObject private var watchConnectivity = WatchConnectivityService()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Glassmorphism background
                Color.black
                    .ignoresSafeArea()
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.black.opacity(0.7),
                        Color.black.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // Messages
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(messages, id: \.self) { message in
                                Text(message)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(.ultraThinMaterial)
                                                .opacity(0.5)
                                            
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.1),
                                                            Color.white.opacity(0.03)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                            
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.25),
                                                            Color.white.opacity(0.08)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 0.6
                                                )
                                        }
                                    )
                                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding()
                    }
                    
                    // Watch Connection Status
                    if watchConnectivity.isWatchReachable {
                        HStack {
                            Image(systemName: "applewatch")
                                .foregroundColor(.green)
                            Text("Watch Connected")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Input
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $messageText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.5)
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.1),
                                                    Color.white.opacity(0.03)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.25),
                                                    Color.white.opacity(0.08)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.6
                                        )
                                }
                            )
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .opacity(0.6)
                                        
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.2),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.4),
                                                        Color.white.opacity(0.2)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.8
                                            )
                                    }
                                )
                                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Simple Chat")
            .preferredColorScheme(.dark)
            .onAppear {
                // Configure navigation bar appearance for dark theme
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
            }
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messages.append("You: \(message)")
        messageText = ""
        isLoading = true
        
        // Send message to Watch if connected
        if watchConnectivity.isWatchReachable {
            let watchMessage = Message(content: message, isFromUser: true)
            watchConnectivity.sendMessageToWatch(watchMessage, conversationId: "current")
        }
        
        // Call real backend API
        Task {
            let result = await backendService.sendTestMessage(message: message)
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let response):
                    let aiResponse = "AI: \(response.response)"
                    messages.append(aiResponse)
                    
                    // Send AI response to Watch if connected
                    if watchConnectivity.isWatchReachable {
                        let watchMessage = Message(content: response.response, isFromUser: false)
                        watchConnectivity.sendMessageToWatch(watchMessage, conversationId: "current")
                    }
                case .failure(let error):
                    let errorMessage = "AI: Error - \(error.localizedDescription)"
                    messages.append(errorMessage)
                }
            }
        }
    }
}

#Preview {
    SimpleChatView()
}
