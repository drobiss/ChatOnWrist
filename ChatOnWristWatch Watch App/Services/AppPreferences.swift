//
//  AppPreferences.swift
//  ChatOnWristWatch Watch App
//
//  Created for managing user preferences
//

import Foundation
import Combine

@MainActor
class AppPreferences: ObservableObject {
    static let shared = AppPreferences()
    
    @Published var fontSize: Double {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: "fontSize")
        }
    }
    
    private init() {
        self.fontSize = UserDefaults.standard.double(forKey: "fontSize")
        if fontSize == 0 {
            fontSize = 12 // Default font size
        }
    }
}
