//
//  DictationService.swift
//  ChatOnWristWatch Watch App
//
//  Created by Codex on 26.10.2025.
//

import Foundation
import Combine
import WatchKit

@MainActor
final class DictationService: ObservableObject {
    private var isPresenting = false
    
    func requestDictation(initialText: String? = nil, completion: @escaping (String?) -> Void) {
        guard !isPresenting else {
            print("⚠️ Dictation already in progress")
            completion(nil)
            return
        }
        
        isPresenting = true
        
        // Use rootInterfaceController to ensure we can present even when sheets are showing
        // Add a small delay to ensure any sheet presentations are settled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            
            // Always use rootInterfaceController to avoid conflicts with SwiftUI sheets
            guard let controller = WKExtension.shared().rootInterfaceController else {
                print("⚠️ No root interface controller available")
                self.isPresenting = false
                completion(nil)
                return
            }
            
            print("🎤 Presenting dictation on root controller")
            
            controller.presentTextInputController(
                withSuggestions: nil,
                allowedInputMode: .allowEmoji
            ) { [weak self] result in
                guard let self = self else { return }
                self.isPresenting = false
                
                print("🎤 Dictation completed, processing result")
                
                // Extract text from result
                if let results = result as? [Any] {
                    for item in results {
                        if let text = item as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            print("🎤 Dictation result: \(text)")
                            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
                            return
                        }
                    }
                }
                
                print("⚠️ No valid text from dictation")
                completion(nil)
            }
        }
    }
}
