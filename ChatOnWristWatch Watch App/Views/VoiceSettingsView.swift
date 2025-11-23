//
//  VoiceSettingsView.swift
//  ChatOnWristWatch Watch App
//
//  Created by Codex on 26.10.2025.
//

import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @StateObject private var speechService = SpeechService()
    @StateObject private var preferences = AppPreferences.shared
    @State private var selectedVoice: AVSpeechSynthesisVoice?
    @State private var speechRate: Double = 0.45
    @State private var speechVolume: Double = 0.9
    @State private var speechPitch: Double = 1.0
    
    var body: some View {
        List {
            Section("Voice") {
                Button(action: {
                    speechService.selectVoice(with: nil)
                    selectedVoice = nil
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Automatic")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Let the app pick the best available voice")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                        if speechService.selectedVoiceIdentifier == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                
                ForEach(speechService.availableVoiceOptions) { option in
                    Button(action: {
                        guard option.isAvailable, let identifier = option.identifier else { return }
                        speechService.selectVoice(with: identifier)
                        selectedVoice = AVSpeechSynthesisVoice(identifier: identifier)
                        testVoice()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(option.subtitle)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                if !option.isAvailable {
                                    Text("Download on iPhone to enable this voice")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                }
                            }
                            Spacer()
                            if let identifier = option.identifier,
                               speechService.selectedVoiceIdentifier == identifier {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(!option.isAvailable)
                    .opacity(option.isAvailable ? 1.0 : 0.5)
                }
            }
            
            Section("Display") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Font Size: \(Int(preferences.fontSize))pt")
                        .font(.system(size: 11))
                    Slider(value: $preferences.fontSize, in: 10...16, step: 1)
                }
            }
            
            Section("Voice Settings") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speed: \(String(format: "%.2f", speechRate))")
                        .font(.system(size: 11))
                    Slider(value: $speechRate, in: 0.1...0.8)
                        .onChange(of: speechRate) { _, _ in
                            testVoice()
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume: \(String(format: "%.1f", speechVolume))")
                        .font(.system(size: 11))
                    Slider(value: $speechVolume, in: 0.1...1.0)
                        .onChange(of: speechVolume) { _, _ in
                            testVoice()
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pitch: \(String(format: "%.1f", speechPitch))")
                        .font(.system(size: 11))
                    Slider(value: $speechPitch, in: 0.5...2.0)
                        .onChange(of: speechPitch) { _, _ in
                            testVoice()
                        }
                }
            }
        }
        .onAppear {
            loadVoices()
        }
    }
    
    private func loadVoices() {
        speechService.refreshAvailableVoices()
        if
            let selectedId = speechService.selectedVoiceIdentifier,
            let voice = AVSpeechSynthesisVoice(identifier: selectedId)
        {
            selectedVoice = voice
        } else {
            selectedVoice = nil
            if speechService.selectedVoiceIdentifier != nil {
                speechService.selectVoice(with: nil)
            }
        }
    }
    
    private func testVoice() {
        guard let voice = selectedVoice else { return }
        
        let utterance = AVSpeechUtterance(string: "Hello, this is a test of the voice settings.")
        utterance.voice = voice
        utterance.rate = Float(speechRate)
        utterance.volume = Float(speechVolume)
        utterance.pitchMultiplier = Float(speechPitch)
        
        speechService.synthesizer.stopSpeaking(at: .immediate)
        speechService.synthesizer.speak(utterance)
    }
}

#Preview {
    VoiceSettingsView()
}
