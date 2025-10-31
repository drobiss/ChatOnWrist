//
//  SpeechService.swift
//  ChatOnWristWatch Watch App
//
//  Created by David Brezina on 22.10.2025.
//

import Foundation
import AVFoundation
import Combine

class SpeechService: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var errorMessage: String?
    @Published private(set) var selectedVoiceIdentifier: String?
    @Published private(set) var availableVoiceOptions: [VoiceOption] = []
    
    let synthesizer = AVSpeechSynthesizer()
    private let userDefaults = UserDefaults.standard
    private let selectedVoiceKey = "watch.selectedVoiceIdentifier"
    private let voiceChoices: [VoiceChoice] = [
        .init(
            id: "samantha",
            displayName: "Samantha",
            baseSubtitle: "US English",
            matchTokens: ["samantha"]
        ),
        .init(
            id: "daniel",
            displayName: "Daniel",
            baseSubtitle: "British English",
            matchTokens: ["daniel"]
        )
    ]
    
    // Voice preferences - prioritized for most natural-sounding voices
    private let preferredVoices = [
        "en-US": "com.apple.voice.enhanced.en-US.Samantha", // Siri Female (Enhanced)
        "en-GB": "com.apple.voice.enhanced.en-GB.Daniel",   // British Male (Enhanced)
        "en-AU": "com.apple.voice.enhanced.en-AU.Karen",    // Australian Female (Enhanced)
        "cs-CZ": "com.apple.voice.enhanced.cs-CZ.Zuzana", 
        "pt-BR": "com.apple.voice.enhanced.pt-BR.Luciana"
    ]
    
    // Natural-sounding voice identifiers in order of preference
    // Note: Enhanced voices are only available on physical devices, not simulator
    private let naturalVoiceIdentifiers = [
        "com.apple.voice.enhanced.en-US.Samantha",     // Siri Female (Enhanced) - Most natural (Physical only)
        "com.apple.voice.enhanced.en-US.Alex",         // Alex (Enhanced) - Very natural (Physical only)
        "com.apple.voice.enhanced.en-GB.Daniel",       // British Male (Enhanced) (Physical only)
        "com.apple.voice.enhanced.en-AU.Karen",        // Australian Female (Enhanced) (Physical only)
        "com.apple.voice.compact.en-US.Samantha",      // Samantha (Compact) - Good fallback
        "com.apple.voice.compact.en-US.Alex",          // Alex (Compact) - Good fallback
        "com.apple.voice.compact.en-GB.Daniel",        // Daniel (Compact) - British
        "com.apple.voice.compact.en-AU.Karen"          // Karen (Compact) - Australian
    ]
    
    // Fallback voices for simulator and older devices
    private let fallbackVoiceNames = [
        "Samantha",    // Most natural standard voice
        "Alex",        // Good male voice
        "Daniel",      // British accent
        "Karen",       // Australian accent
        "Tessa",       // South African accent
        "Moira"        // Irish accent
    ]
    
    override init() {
        super.init()
        synthesizer.delegate = self
        selectedVoiceIdentifier = userDefaults.string(forKey: selectedVoiceKey)
        refreshAvailableVoices()
        
        // List available voices for debugging (only once)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.listAvailableVoices()
        }
    }
    
    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        print("🔊 Speaking: \(trimmed)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Configure audio session for playback on watchOS
            // Use simplest configuration that works on watchOS
            do {
                let session = AVAudioSession.sharedInstance()
                // Just use .playback category without mode for maximum compatibility
                try session.setCategory(.playback)
                try session.setActive(true)
                print("✅ Audio session configured")
            } catch {
                print("❌ Audio session error: \(error.localizedDescription)")
                // If even basic config fails, continue anyway - TTS might still work
                print("⚠️ Continuing without audio session configuration")
            }
            
            // Detect language and select best voice
            let language = self.detectLanguage(text: trimmed)
            let voice = self.selectBestVoice(for: language)
            
            let utterance = AVSpeechUtterance(string: trimmed)
            
            // Optimized speech parameters for most natural-sounding output
            utterance.rate = 0.48  // Slightly slower for natural pace
            utterance.pitchMultiplier = 1.05  // Slightly higher pitch for warmth
            utterance.volume = 0.95  // High volume for clarity
            utterance.voice = voice
            
            // Natural pauses for human-like speech flow
            utterance.preUtteranceDelay = 0.15
            utterance.postUtteranceDelay = 0.25
            
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            
            self.isSpeaking = true
            self.synthesizer.speak(utterance)
            print("🔊 Speech started with voice: \(voice.name) (\(voice.language))")
        }
    }
    
    // Debug method to list available voices
    func listAvailableVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        print("🎤 Available voices:")
        
        // Group voices by language
        let englishVoices = voices.filter { $0.language.hasPrefix("en") }
        let enhancedVoices = voices.filter { $0.name.contains("Enhanced") }
        
        print("📱 English voices:")
        for voice in englishVoices {
            let isEnhanced = voice.name.contains("Enhanced")
            let isNatural = naturalVoiceIdentifiers.contains(voice.identifier)
            print("  - \(voice.name) (\(voice.language)) - Enhanced: \(isEnhanced) - Natural: \(isNatural)")
        }
        
        print("📱 Enhanced voices:")
        for voice in enhancedVoices {
            print("  - \(voice.name) (\(voice.language))")
        }
        
        print("📱 Total voices: \(voices.count)")
    }
    
    private func detectLanguage(text: String) -> String {
        let lowercased = text.lowercased()
        
        // Czech/Slovak - more comprehensive detection
        if lowercased.contains("čau") || lowercased.contains("jak") || lowercased.contains("hovno") || 
           lowercased.contains("děkuji") || lowercased.contains("prosím") || lowercased.contains("dobrý") {
            return "cs-CZ"
        }
        
        // Portuguese - more comprehensive detection
        if lowercased.contains("olá") || lowercased.contains("como") || lowercased.contains("posso") || 
           lowercased.contains("você") || lowercased.contains("obrigado") || lowercased.contains("por favor") {
            return "pt-BR"
        }
        
        // Spanish detection
        if lowercased.contains("hola") || lowercased.contains("gracias") || lowercased.contains("por favor") ||
           lowercased.contains("cómo") || lowercased.contains("puedo") {
            return "es-ES"
        }
        
        // French detection
        if lowercased.contains("bonjour") || lowercased.contains("merci") || lowercased.contains("s'il vous plaît") ||
           lowercased.contains("comment") || lowercased.contains("pouvez") {
            return "fr-FR"
        }
        
        // German detection
        if lowercased.contains("hallo") || lowercased.contains("danke") || lowercased.contains("bitte") ||
           lowercased.contains("wie") || lowercased.contains("kann") {
            return "de-DE"
        }
        
        // Default to English
        return "en-US"
    }
    
    private func selectBestVoice(for language: String) -> AVSpeechSynthesisVoice {
        // For English, try to get the most natural-sounding voice
        if language.hasPrefix("en") {
            return selectMostNaturalEnglishVoice()
        }
        
        // For other languages, try to get the preferred enhanced voice first
        if let preferredVoiceIdentifier = preferredVoices[language],
           let preferredVoice = AVSpeechSynthesisVoice(identifier: preferredVoiceIdentifier) {
            print("🎤 Using preferred voice: \(preferredVoice.name) (\(preferredVoice.language))")
            return preferredVoice
        }
        
        // Fallback to any enhanced voice for the language
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        let enhancedVoices = availableVoices.filter { voice in
            voice.language.hasPrefix(language) && voice.name.contains("Enhanced")
        }
        
        if let enhancedVoice = enhancedVoices.first {
            print("🎤 Using enhanced voice: \(enhancedVoice.name) (\(enhancedVoice.language))")
            return enhancedVoice
        }
        
        // Fallback to any voice for the language
        if let languageVoice = AVSpeechSynthesisVoice(language: language) {
            print("🎤 Using language voice: \(languageVoice.name) (\(languageVoice.language))")
            return languageVoice
        }
        
        // Final fallback to English
        return selectMostNaturalEnglishVoice()
    }
    
    private func selectMostNaturalEnglishVoice() -> AVSpeechSynthesisVoice {
        let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        
        if
            let selectedVoiceIdentifier,
            let selectedVoice = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier),
            selectedVoice.language.hasPrefix("en")
        {
            print("🎤 Using user selected voice: \(selectedVoice.name) (\(selectedVoice.language))")
            return selectedVoice
        }
        
        // Try each natural voice identifier in order of preference
        for voiceIdentifier in naturalVoiceIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
                print("🎤 Using natural voice: \(voice.name) (\(voice.language))")
                return voice
            }
        }
        
        // Try to find voices by name (for simulator compatibility)
        for voiceName in fallbackVoiceNames {
            if let voice = availableVoices.first(where: { 
                $0.name == voiceName && $0.language.hasPrefix("en") 
            }) {
                print("🎤 Using fallback voice by name: \(voice.name) (\(voice.language))")
                return voice
            }
        }
        
        // Fallback to any enhanced English voice (if available on physical device)
        let enhancedEnglishVoices = availableVoices.filter { voice in
            voice.language.hasPrefix("en") && voice.name.contains("Enhanced")
        }
        
        if let enhancedVoice = enhancedEnglishVoices.first {
            print("🎤 Using enhanced English voice: \(enhancedVoice.name) (\(enhancedVoice.language))")
            return enhancedVoice
        }
        
        // Try to find the best standard English voice
        let standardEnglishVoices = availableVoices.filter { voice in
            voice.language.hasPrefix("en") && !voice.name.contains("Enhanced") && 
            !voice.name.contains("Bad News") && !voice.name.contains("Bahh") &&
            !voice.name.contains("Bells") && !voice.name.contains("Boing") &&
            !voice.name.contains("Bubbles") && !voice.name.contains("Cellos") &&
            !voice.name.contains("Wobble") && !voice.name.contains("Fred") &&
            !voice.name.contains("Good News") && !voice.name.contains("Jester") &&
            !voice.name.contains("Junior") && !voice.name.contains("Kathy") &&
            !voice.name.contains("Organ") && !voice.name.contains("Superstar") &&
            !voice.name.contains("Ralph") && !voice.name.contains("Trinoids") &&
            !voice.name.contains("Whisper") && !voice.name.contains("Zarvox")
        }
        
        if let standardVoice = standardEnglishVoices.first {
            print("🎤 Using standard English voice: \(standardVoice.name) (\(standardVoice.language))")
            return standardVoice
        }
        
        // Final fallback to any English voice
        if let englishVoice = AVSpeechSynthesisVoice(language: "en-US") {
            print("🎤 Using fallback English voice: \(englishVoice.name) (\(englishVoice.language))")
            return englishVoice
        }

        // Absolute fallback
        let fallbackVoice = AVSpeechSynthesisVoice.speechVoices().first!
        print("🎤 Using absolute fallback voice: \(fallbackVoice.name) (\(fallbackVoice.language))")
        return fallbackVoice
    }
    
    func selectVoice(with identifier: String?) {
        selectedVoiceIdentifier = identifier
        if let identifier {
            userDefaults.set(identifier, forKey: selectedVoiceKey)
        } else {
            userDefaults.removeObject(forKey: selectedVoiceKey)
        }
    }
    
    func refreshAvailableVoices() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let options = voiceChoices.map { choice -> VoiceOption in
            let match = voices.first { voice in
                let lowerName = voice.name.lowercased()
                let lowerIdentifier = voice.identifier.lowercased()
                return choice.matchTokens.contains(where: { token in
                    lowerName.contains(token) || lowerIdentifier.contains(token)
                })
            }
            
            let subtitle: String
            if let match = match {
                let languageDescription = Self.languageDescription(for: match)
                let enhancedSuffix = match.name.contains("Enhanced") ? "Enhanced" : nil
                let parts = [languageDescription.isEmpty ? nil : languageDescription, enhancedSuffix].compactMap { $0 }
                subtitle = parts.isEmpty ? choice.baseSubtitle : parts.joined(separator: " · ")
            } else {
                subtitle = choice.baseSubtitle
            }
            
            return VoiceOption(
                id: choice.id,
                identifier: match?.identifier,
                displayName: choice.displayName,
                subtitle: subtitle,
                isAvailable: match != nil
            )
        }
        
        if let selectedVoiceIdentifier,
           !voices.contains(where: { $0.identifier == selectedVoiceIdentifier }) {
            selectVoice(with: nil)
        }
        
        availableVoiceOptions = options
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            print("🔊 Speech finished")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            print("🔊 Speech cancelled")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🔊 Speech actually started")
    }
}

extension SpeechService {
    struct VoiceOption: Identifiable {
        let id: String
        let identifier: String?
        let displayName: String
        let subtitle: String
        let isAvailable: Bool
    }
    
    private struct VoiceChoice {
        let id: String
        let displayName: String
        let baseSubtitle: String
        let matchTokens: [String]
    }
    
    private static func languageDescription(for voice: AVSpeechSynthesisVoice) -> String {
        let components = voice.language.split(separator: "-")
        guard let languageCode = components.first else { return voice.language }
        
        var pieces: [String] = []
        if let languageName = Locale.current.localizedString(forLanguageCode: String(languageCode)) {
            pieces.append(languageName)
        }
        
        if components.count > 1 {
            let regionCode = String(components[1])
            if let regionName = Locale.current.localizedString(forRegionCode: regionCode) {
                pieces.append(regionName)
            }
        }
        
        return pieces.joined(separator: " · ")
    }
}
