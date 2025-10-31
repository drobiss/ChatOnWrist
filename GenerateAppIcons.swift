//
//  GenerateAppIcons.swift
//  ChatOnWrist
//
//  Created by David Brezina on 29.10.2025.
//

import SwiftUI
import AppKit

// This script generates app icons in various sizes
// Run this in Xcode or as a standalone Swift script

func generateAppIcon(size: CGFloat, filename: String) {
    let iconView = AppIconGenerator(size: size)
    let hostingView = NSHostingView(rootView: iconView)
    hostingView.frame = CGRect(x: 0, y: 0, width: size, height: size)
    
    // Create image from view
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    hostingView.layer?.render(in: NSGraphicsContext.current!.cgContext)
    image.unlockFocus()
    
    // Save as PNG
    if let tiffData = image.tiffRepresentation,
       let bitmapRep = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapRep.representation(using: .png, properties: [:]) {
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try pngData.write(to: fileURL)
            print("✅ Generated \(filename) at \(fileURL.path)")
        } catch {
            print("❌ Error saving \(filename): \(error)")
        }
    }
}

// Generate all required icon sizes
let iconSizes: [(CGFloat, String)] = [
    (1024, "AppIcon-1024.png"),
    (180, "AppIcon-180.png"),
    (167, "AppIcon-167.png"),
    (152, "AppIcon-152.png"),
    (120, "AppIcon-120.png"),
    (87, "AppIcon-87.png"),
    (80, "AppIcon-80.png"),
    (76, "AppIcon-76.png"),
    (60, "AppIcon-60.png"),
    (58, "AppIcon-58.png"),
    (40, "AppIcon-40.png"),
    (29, "AppIcon-29.png"),
    (20, "AppIcon-20.png")
]

print("🎨 Generating ChatOnWrist App Icons...")
print("📱 This will create icons in various sizes for iOS and Watch apps")
print("")

for (size, filename) in iconSizes {
    generateAppIcon(size: size, filename: filename)
}

print("")
print("🎉 All app icons generated successfully!")
print("📁 Icons are saved in your Documents folder")
print("")
print("📋 Next steps:")
print("1. Copy the generated PNG files to your Assets.xcassets/AppIcon.appiconset/ folders")
print("2. Update the Contents.json files if needed")
print("3. Build and run your app to see the new icons!")
