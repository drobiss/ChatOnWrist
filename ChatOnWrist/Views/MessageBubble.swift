//
//  MessageBubble.swift
//  ChatOnWrist
//
//  Created by David Brezina on 22.10.2025.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 40)
                
                Text(message.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(iOSPalette.accent)
                    )
            } else {
                Text(message.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(iOSPalette.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(iOSPalette.glassBorder, lineWidth: 0.5)
                            )
                    )
                
                Spacer(minLength: 40)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(message: Message(content: "Hello, how can I help you?", isFromUser: true))
        MessageBubble(message: Message(content: "I'm here to assist you with any questions you have!", isFromUser: false))
    }
    .padding()
    .background(Color.black)
}
