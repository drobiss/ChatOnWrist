//
//  AppConfig.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation

struct AppConfig {
    // OpenAI API configuration
    // Loads from environment variables or local config
    static let openAIAPIKey: String = {
        // Try to load from environment variable first
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Fallback to local config (for development)
        // This file is in .gitignore so it won't be pushed to GitHub
        if let localConfig = loadLocalConfig() {
            return localConfig.openAIAPIKey
        }
        
        // Final fallback (safe for GitHub)
        return "YOUR_OPENAI_API_KEY_HERE"
    }()
    
    // Backend API configuration
    // Use production server for both DEBUG and RELEASE builds
    static let backendBaseURL = "https://chatonwrist-production-79ac.up.railway.app"
    
    // App settings
    static let maxTokens = 150
    static let temperature = 0.7
    static let model = "gpt-4o"
    
    // MARK: - Local Configuration Loading
    
    private static func loadLocalConfig() -> LocalConfig? {
        guard let path = Bundle.main.path(forResource: "LocalConfig", ofType: "plist"),
              let data = NSData(contentsOfFile: path),
              let plist = try? PropertyListSerialization.propertyList(from: data as Data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        
        return LocalConfig(
            openAIAPIKey: plist["OPENAI_API_KEY"] as? String ?? ""
        )
    }
}

struct LocalConfig {
    let openAIAPIKey: String
}