//
//  IconPreview.swift
//  ChatOnWrist
//
//  Created by David Brezina on 29.10.2025.
//

import SwiftUI

struct IconPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("ChatOnWrist App Icon Preview")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                // iOS App Icon
                VStack {
                    Text("iOS App Icon")
                        .font(.headline)
                    AppIconGenerator(size: 120)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                }
                
                // Watch App Icon
                VStack {
                    Text("Watch App Icon")
                        .font(.headline)
                    AppIconGenerator(size: 120)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                }
            }
            
            Text("Instructions:")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Take a screenshot of this preview")
                Text("2. Crop to 1024x1024 pixels")
                Text("3. Save as AppIcon.png")
                Text("4. Add to Assets.xcassets/AppIcon.appiconset/")
            }
            .font(.body)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    IconPreview()
}
