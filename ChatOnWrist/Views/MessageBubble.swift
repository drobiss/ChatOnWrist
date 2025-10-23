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
        HStack {
            if isFromUser {
                Spacer()
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromUser ? Color.blue : Color(.systemGray5))
                    )
                    .foregroundColor(isFromUser ? .white : .primary)
                
                Text(timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromUser {
                Spacer()
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
