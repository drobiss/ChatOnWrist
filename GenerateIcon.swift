#!/usr/bin/env swift

import Foundation
import SwiftUI
import AppKit

// Simple command-line tool to generate app icon
// Run with: swift GenerateIcon.swift

struct AppIcon: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.15),
                            Color(red: 0.25, green: 0.25, blue: 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Smartwatch
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(Color.white)
                .frame(width: size * 0.35, height: size * 0.45)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.05)
                        .fill(Color.black)
                        .frame(width: size * 0.25, height: size * 0.3)
                )
            
            // Watch straps
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Color.white)
                .frame(width: size * 0.15, height: size * 0.25)
                .offset(y: -size * 0.35)
            
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Color.white)
                .frame(width: size * 0.15, height: size * 0.25)
                .offset(y: size * 0.35)
            
            // Speech bubble
            SpeechBubble()
                .fill(Color.white)
                .frame(width: size * 0.4, height: size * 0.25)
                .offset(x: size * 0.15, y: -size * 0.1)
            
            // Microphone
            MicrophoneIcon()
                .fill(Color.black)
                .frame(width: size * 0.08, height: size * 0.12)
                .offset(x: size * 0.15, y: -size * 0.1)
        }
    }
}

struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = rect.width * 0.15
        
        path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height * 0.8), cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        let tailWidth = rect.width * 0.15
        let tailHeight = rect.height * 0.2
        let tailX = rect.width * 0.2
        let tailY = rect.height * 0.8
        
        path.move(to: CGPoint(x: tailX, y: tailY))
        path.addLine(to: CGPoint(x: tailX + tailWidth * 0.5, y: tailY + tailHeight))
        path.addLine(to: CGPoint(x: tailX + tailWidth, y: tailY))
        path.closeSubpath()
        
        return path
    }
}

struct MicrophoneIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let headRect = CGRect(x: rect.width * 0.2, y: 0, width: rect.width * 0.6, height: rect.height * 0.6)
        path.addEllipse(in: headRect)
        
        let standWidth = rect.width * 0.3
        let standHeight = rect.height * 0.4
        let standX = (rect.width - standWidth) / 2
        let standY = rect.height * 0.6
        
        path.addRect(CGRect(x: standX, y: standY, width: standWidth, height: standHeight))
        
        let baseWidth = rect.width * 0.6
        let baseHeight = rect.height * 0.2
        let baseX = (rect.width - baseWidth) / 2
        let baseY = rect.height * 0.8
        
        path.addRect(CGRect(x: baseX, y: baseY, width: baseWidth, height: baseHeight))
        
        return path
    }
}

// Generate the icon
let iconView = AppIcon(size: 1024)
let hostingView = NSHostingView(rootView: iconView)
hostingView.frame = CGRect(x: 0, y: 0, width: 1024, height: 1024)

let image = NSImage(size: NSSize(width: 1024, height: 1024))
image.lockFocus()
hostingView.layer?.render(in: NSGraphicsContext.current!.cgContext)
image.unlockFocus()

if let tiffData = image.tiffRepresentation,
   let bitmapRep = NSBitmapImageRep(data: tiffData),
   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
    
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsPath.appendingPathComponent("AppIcon-1024.png")
    
    do {
        try pngData.write(to: fileURL)
        print("✅ App icon generated successfully!")
        print("📁 Saved to: \(fileURL.path)")
        print("📱 Copy this file to your Assets.xcassets/AppIcon.appiconset/ folder")
    } catch {
        print("❌ Error saving icon: \(error)")
    }
} else {
    print("❌ Error generating icon")
}
