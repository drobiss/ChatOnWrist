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
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    @Published var isAuthorized = false
    
    private let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        requestPermissions()
    }
    
    // MARK: - Permissions
    
    private func requestPermissions() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if !granted {
                    self?.errorMessage = "Microphone permission denied"
                }
            }
        }
    }
    
    // MARK: - Speech Recognition (Simplified for watchOS)
    
    func startRecording() {
        guard isAuthorized else {
            errorMessage = "Microphone not authorized"
            return
        }
        
        guard !isRecording else { return }
        
        do {
            try startAudioSession()
            try startAudioRecording()
            isRecording = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        isRecording = false
        
        // For watchOS, we'll use a simple text input as fallback
        // In a real implementation, you'd send the audio to a speech recognition service
        recognizedText = "Voice input recorded (transcription would happen here)"
    }
    
    private func startAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func startAudioRecording() throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            // In a real implementation, you would process the audio buffer here
            // and send it to a speech recognition service
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}

// MARK: - Text-to-Speech

extension SpeechService {
    func speak(_ text: String) {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}

// MARK: - Error Types

enum SpeechError: Error, LocalizedError {
    case audioEngineFailed
    
    var errorDescription: String? {
        switch self {
        case .audioEngineFailed:
            return "Audio engine failed to start"
        }
    }
}

