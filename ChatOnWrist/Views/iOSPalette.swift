//
//  iOSPalette.swift
//  ChatOnWrist
//
//  Created for iOS Liquid Glass design system
//

import SwiftUI

/// iOS Liquid Glass design system - matching watchOS design
enum iOSPalette {
    static let background = Color.black
    static let backgroundGlow = LinearGradient(
        colors: [
            Color(red: 12/255, green: 24/255, blue: 48/255).opacity(0.6),
            Color.black
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accent = Color(red: 25/255, green: 149/255, blue: 254/255) // #1995fe
    static let accentHighlight = Color(red: 80/255, green: 180/255, blue: 1.0)
    static let accentShadow = Color(red: 0/255, green: 70/255, blue: 180/255)
    
    static let glassSurface = Color.white.opacity(0.12)
    static let glassBorder = Color.white.opacity(0.22)
    static let surface = glassSurface
    
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.45)
}
