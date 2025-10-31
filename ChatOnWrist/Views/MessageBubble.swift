//
//  MessageBubble.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct MessageBubble: View {
    let message: String
    let isFromUser: Bool
    let timestamp: Date
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isFromUser {
                Spacer(minLength: 24)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                // Glass effect
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.6)
                                
                                // Minimal gradient overlay
                                RoundedRectangle(cornerRadius: 18)
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
                                
                                // Border
                                RoundedRectangle(cornerRadius: 18)
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
                        .multilineTextAlignment(.trailing)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1.5)
                        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 0.5)
                    
                    Text(timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                // Glass effect
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.5)
                                
                                // Minimal gradient overlay
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
                                
                                // Border
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
                        .multilineTextAlignment(.leading)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .shadow(color: .white.opacity(0.03), radius: 0.5, x: 0, y: 0.25)
                    
                    Text(timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer(minLength: 24)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        MessageBubble(
            message: "Hello, how are you?",
            isFromUser: true,
            timestamp: Date()
        )
        
        MessageBubble(
            message: "I'm doing well, thank you for asking!",
            isFromUser: false,
            timestamp: Date()
        )
    }
}
