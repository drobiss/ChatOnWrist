//
//  DictationService.swift
//  ChatOnWristWatch Watch App
//
//  Created by Codex on 26.10.2025.
//

import Foundation
import Combine
#if os(watchOS)
import WatchKit
#endif

@MainActor
final class DictationService: ObservableObject {
    private var isPresenting = false
    
    func requestDictation(initialText: String? = nil, completion: @escaping (String?) -> Void) {
        #if os(watchOS)
        // Prevent concurrent presentations
        guard !isPresenting else {
            print("⚠️ Dictation already presenting, ignoring request")
            completion(nil)
            return
        }
        
        guard let controller = WKExtension.shared().visibleInterfaceController else {
            print("⚠️ No visible interface controller for dictation")
            completion(nil)
            return
        }
        
        // Check if interface controller is already presenting something
        // This is a best-effort check - actual prevention is via isPresenting flag
        isPresenting = true
        let suggestions = (initialText?.isEmpty == false) ? [initialText!] : nil
        
        // Small delay to ensure any dismissal animations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            
            controller.presentTextInputController(withSuggestions: suggestions, allowedInputMode: .plain) { [weak self] result in
                guard let self = self else { return }
                self.isPresenting = false
                let text = (result?.first as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                completion(text)
            }
        }
        #else
        // Not available on iOS
        completion(nil)
        #endif
    }
}
