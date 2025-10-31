//
//  PresentationManager.swift
//  ChatOnWristWatch Watch App
//
//  Created by Codex on 26.10.2025.
//

import Foundation
import Combine

@MainActor
final class PresentationManager: ObservableObject {
    static let shared = PresentationManager()
    
    @Published private(set) var isAnyPresentationActive = false
    
    private init() {}
    
    func setPresentationActive(_ active: Bool) {
        isAnyPresentationActive = active
        print("📱 Presentation state changed: \(active)")
    }
    
    func canPresent() -> Bool {
        return !isAnyPresentationActive
    }
}

