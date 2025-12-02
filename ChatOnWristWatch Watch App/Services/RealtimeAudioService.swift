//
//  RealtimeAudioService.swift
//  ChatOnWristWatch Watch App
//
//  Created for real-time voice chat with OpenAI Realtime API
//

import Foundation
import AVFoundation
import Combine

@MainActor
class RealtimeAudioService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var audioFormat: AVAudioFormat?
    private var audioBuffer: [Float] = []
    
    // Playback components
    private var playbackEngine: AVAudioEngine?
    private var playbackPlayerNode: AVAudioPlayerNode?
    private var playbackBuffer: [Data] = []
    private var isPlaybackReady = false
    
    // Audio configuration for OpenAI Realtime API
    private let sampleRate: Double = 24000 // OpenAI Realtime API requires 24kHz
    private let channels: UInt32 = 1 // Mono
    private let bitDepth: Int = 16 // 16-bit PCM
    
    // Callback for audio chunks
    var onAudioChunk: ((Data) -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)
            print("✅ Audio session configured for recording")
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
            errorMessage = "Failed to configure audio: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        guard !isRecording else {
            print("⚠️ Already recording")
            return
        }
        
        // Reset state
        audioBuffer.removeAll()
        errorMessage = nil
        
        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            errorMessage = "Failed to create audio engine"
            return
        }
        
        // Get input node
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        print("📊 Input format: sampleRate=\(inputFormat.sampleRate), channels=\(inputFormat.channelCount)")
        
        // Create target format: 24kHz, mono, 16-bit PCM
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        ) else {
            errorMessage = "Failed to create target audio format"
            return
        }
        
        audioFormat = targetFormat
        
        // Install tap on input node
        let bufferSize: AVAudioFrameCount = 4096
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        // Start engine
        do {
            try engine.start()
            isRecording = true
            print("🎤 Recording started")
        } catch {
            print("❌ Failed to start audio engine: \(error.localizedDescription)")
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            audioEngine?.stop()
            audioEngine = nil
        }
    }
    
    func stopRecording() {
        guard isRecording else {
            return
        }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        isRecording = false
        print("🛑 Recording stopped")
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let targetFormat = audioFormat,
              let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else {
            print("⚠️ Failed to create audio converter")
            return
        }
        
        // Calculate output buffer size
        let inputSampleRate = buffer.format.sampleRate
        let outputSampleRate = targetFormat.sampleRate
        let ratio = outputSampleRate / inputSampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCapacity
        ) else {
            print("⚠️ Failed to create output buffer")
            return
        }
        
        // Convert audio format
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
        
        if let error = error {
            print("❌ Audio conversion error: \(error.localizedDescription)")
            return
        }
        
        // Extract PCM16 data
        guard let channelData = outputBuffer.int16ChannelData else {
            print("⚠️ No channel data available")
            return
        }
        
        let frameLength = Int(outputBuffer.frameLength)
        let audioData = Data(bytes: channelData.pointee, count: frameLength * MemoryLayout<Int16>.size)
        
        // Send audio chunk via callback
        onAudioChunk?(audioData)
    }
    
    // MARK: - Audio Playback
    
    func setupPlayback() {
        guard playbackEngine == nil else {
            print("⚠️ Playback already set up")
            return
        }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            
            playbackEngine = AVAudioEngine()
            guard let engine = playbackEngine else {
                errorMessage = "Failed to create playback engine"
                return
            }
            
            playbackPlayerNode = AVAudioPlayerNode()
            guard let playerNode = playbackPlayerNode else {
                errorMessage = "Failed to create player node"
                return
            }
            
            // Create playback format (24kHz, mono, 16-bit PCM)
            guard let playbackFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: sampleRate,
                channels: channels,
                interleaved: false
            ) else {
                errorMessage = "Failed to create playback format"
                return
            }
            
            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.mainMixerNode, format: playbackFormat)
            
            try engine.start()
            playerNode.play()
            
            isPlaybackReady = true
            print("✅ Playback engine ready")
        } catch {
            print("❌ Failed to setup playback: \(error.localizedDescription)")
            errorMessage = "Playback setup failed: \(error.localizedDescription)"
        }
    }
    
    func playAudioChunk(_ audioData: Data) {
        guard isPlaybackReady,
              let engine = playbackEngine,
              let playerNode = playbackPlayerNode,
              let playbackFormat = AVAudioFormat(
                  commonFormat: .pcmFormatInt16,
                  sampleRate: sampleRate,
                  channels: channels,
                  interleaved: false
              ) else {
            // Setup playback if not ready
            setupPlayback()
            
            // Queue audio for later playback
            playbackBuffer.append(audioData)
            return
        }
        
        // Convert Data to AVAudioPCMBuffer
        let frameCount = audioData.count / MemoryLayout<Int16>.size
        guard let buffer = AVAudioPCMBuffer(pcmFormat: playbackFormat, frameCapacity: AVAudioFrameCount(frameCount)) else {
            print("⚠️ Failed to create playback buffer")
            return
        }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Copy audio data to buffer
        audioData.withUnsafeBytes { bytes in
            guard let int16Pointer = bytes.bindMemory(to: Int16.self).baseAddress else { return }
            buffer.int16ChannelData?.pointee.assign(from: int16Pointer, count: frameCount)
        }
        
        // Play buffer
        playerNode.scheduleBuffer(buffer) { [weak self] in
            // Buffer playback completed
        }
        
        if !isPlaying {
            isPlaying = true
        }
        
        // Process any queued buffers
        if !playbackBuffer.isEmpty {
            let queued = playbackBuffer
            playbackBuffer.removeAll()
            queued.forEach { playAudioChunk($0) }
        }
    }
    
    func stopPlayback() {
        playbackPlayerNode?.stop()
        playbackEngine?.stop()
        playbackEngine = nil
        playbackPlayerNode = nil
        playbackBuffer.removeAll()
        isPlaybackReady = false
        isPlaying = false
        print("🛑 Playback stopped")
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopRecording()
        stopPlayback()
    }
}

