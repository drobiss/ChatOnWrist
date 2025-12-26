# ChatGPT-Like Voice Chat Implementation Plan

## Overview
Replace dictation + TTS with real-time audio streaming using GPT Realtime API.

---

## 🏗️ **ARCHITECTURE**

```
Watch App (Audio Recording)
    ↓ (WebSocket)
Backend Server (WebSocket Proxy)
    ↓ (WebSocket)
OpenAI Realtime API
    ↓ (Audio Stream)
Backend Server
    ↓ (WebSocket)
Watch App (Audio Playback)
```

---

## 📋 **STEP-BY-STEP IMPLEMENTATION**

### **PHASE 1: Backend WebSocket Server**

#### 1.1 Install Dependencies
```bash
cd backend
npm install ws openai
```

#### 1.2 Create WebSocket Route
- File: `backend/routes/realtime.js`
- Handle WebSocket connections
- Proxy audio between Watch and OpenAI Realtime API
- Manage connection lifecycle

#### 1.3 OpenAI Realtime Integration
- Connect to `wss://api.openai.com/v1/realtime`
- Handle audio streaming
- Convert audio formats if needed
- Manage conversation state

---

### **PHASE 2: Watch App - Audio Recording**

#### 2.1 Create RealtimeAudioService
- File: `ChatOnWristWatch Watch App/Services/RealtimeAudioService.swift`
- Use `AVAudioEngine` for real-time recording
- Record audio in chunks (e.g., 100ms buffers)
- Encode audio (PCM → Opus/WebM or send raw PCM)
- Stream to backend via WebSocket

#### 2.2 Audio Session Configuration
- Category: `.playAndRecord`
- Mode: `.voiceChat` or `.videoChat`
- Options: `.defaultToSpeaker`, `.allowBluetooth`

#### 2.3 WebSocket Client
- Use `URLSessionWebSocketTask`
- Send audio chunks as binary data
- Handle connection/reconnection
- Manage connection state

---

### **PHASE 3: Watch App - Audio Playback**

#### 3.1 Audio Playback Service
- Use `AVAudioEngine` or `AVAudioPlayerNode`
- Receive audio chunks from WebSocket
- Decode audio (if encoded)
- Play audio in real-time
- Handle interruptions (calls, notifications)

#### 3.2 Streaming Playback
- Buffer incoming audio chunks
- Play as chunks arrive (low latency)
- Handle gaps/buffering gracefully

---

### **PHASE 4: UI Changes**

#### 4.1 Replace Dictation Button
- Change from dictation to voice recording
- Show recording state (pulsing mic icon)
- Show "listening" indicator
- Show "speaking" indicator when AI responds

#### 4.2 Voice Chat View
- File: `ChatOnWristWatch Watch App/Views/VoiceChatView.swift`
- Push-to-talk button (hold to speak)
- Or toggle button (tap to start/stop)
- Visual feedback (waveform animation)
- Connection status indicator

---

### **PHASE 5: Integration**

#### 5.1 Replace Current Flow
- Remove `DictationService` usage
- Remove `SpeechService.speak()` for responses
- Use `RealtimeAudioService` for both input/output

#### 5.2 Conversation Management
- Keep conversation history
- Send conversation context to OpenAI
- Handle interruptions gracefully

---

## 🔧 **TECHNICAL DETAILS**

### **Audio Format Requirements**

**OpenAI Realtime API:**
- Format: Opus (WebM container) or PCM
- Sample Rate: 24kHz recommended
- Channels: Mono
- Bit Depth: 16-bit

**Watch Recording:**
- Use `AVAudioFormat` with:
  - Sample Rate: 24000 Hz
  - Channels: 1 (mono)
  - Bit Depth: 16-bit
  - Format: Linear PCM or Opus

### **WebSocket Protocol**

**Message Types:**
```swift
// From Watch to Backend
{
  "type": "audio_chunk",
  "data": <base64_encoded_audio>,
  "conversation_id": "uuid"
}

// From Backend to Watch
{
  "type": "audio_response",
  "data": <base64_encoded_audio>
}

{
  "type": "transcript",
  "text": "user said..."
}

{
  "type": "error",
  "message": "..."
}
```

### **Backend WebSocket Handler**

```javascript
// Pseudo-code structure
wss.on('connection', (ws) => {
  // Create OpenAI Realtime connection
  const openaiWS = new WebSocket('wss://api.openai.com/v1/realtime');
  
  // Forward audio from Watch to OpenAI
  ws.on('message', (audioChunk) => {
    openaiWS.send(audioChunk);
  });
  
  // Forward audio from OpenAI to Watch
  openaiWS.on('message', (audioResponse) => {
    ws.send(audioResponse);
  });
});
```

---

## 📦 **FILES TO CREATE/MODIFY**

### **New Files:**
1. `backend/routes/realtime.js` - WebSocket server
2. `ChatOnWristWatch Watch App/Services/RealtimeAudioService.swift` - Audio recording/playback
3. `ChatOnWristWatch Watch App/Services/RealtimeWebSocketService.swift` - WebSocket client
4. `ChatOnWristWatch Watch App/Views/VoiceChatView.swift` - Voice chat UI

### **Modify Files:**
1. `backend/server.js` - Add WebSocket server
2. `backend/package.json` - Add `ws` dependency
3. `ChatOnWristWatch Watch App/Views/WatchChatView.swift` - Replace dictation with voice recording
4. `ChatOnWristWatch Watch App/Services/DictationService.swift` - Deprecate or remove

---

## ⚠️ **CHALLENGES & CONSIDERATIONS**

### **1. Battery Life**
- Continuous audio recording/playback drains battery
- Solution: Use push-to-talk (not always-on)
- Optimize audio buffer sizes

### **2. Network Reliability**
- WebSocket can disconnect
- Solution: Implement reconnection logic
- Buffer audio during disconnection

### **3. Audio Quality**
- Watch microphone quality is limited
- Solution: Use noise reduction
- Optimize audio format for Watch

### **4. Latency**
- Network + processing latency
- Solution: Stream audio in small chunks
- Start playback before full response received

### **5. Background Audio**
- Watch may pause audio when screen locks
- Solution: Configure audio session properly
- Request background audio capability

---

## 🎯 **IMPLEMENTATION ORDER**

### **Week 1: Backend Foundation**
1. ✅ Set up WebSocket server
2. ✅ Connect to OpenAI Realtime API
3. ✅ Test audio proxying

### **Week 2: Watch Audio Recording**
1. ✅ Implement AVAudioEngine recording
2. ✅ Encode audio chunks
3. ✅ Send to backend via WebSocket

### **Week 3: Watch Audio Playback**
1. ✅ Receive audio from WebSocket
2. ✅ Decode audio chunks
3. ✅ Play audio in real-time

### **Week 4: UI & Integration**
1. ✅ Create voice chat UI
2. ✅ Replace dictation flow
3. ✅ Test end-to-end

### **Week 5: Polish & Optimization**
1. ✅ Handle edge cases
2. ✅ Optimize battery usage
3. ✅ Improve audio quality
4. ✅ Error handling

---

## 💰 **COST ESTIMATE**

**OpenAI Realtime API:**
- ~$0.06 per minute of audio
- Average conversation: 2-5 minutes
- Cost per conversation: $0.12 - $0.30

**Backend Infrastructure:**
- WebSocket server (Railway)
- Minimal additional cost
- Same hosting as current backend

---

## ✅ **SUCCESS CRITERIA**

1. ✅ Real-time voice input (no dictation)
2. ✅ Real-time audio output (no TTS)
3. ✅ Natural conversation flow
4. ✅ Works on physical Watch (not just simulator)
5. ✅ Reasonable battery usage (< 10% per 5-min conversation)
6. ✅ Handles network interruptions gracefully

---

## 🚀 **QUICK START (If You Want to Begin)**

I can start implementing this step-by-step. Would you like me to:

1. **Start with backend** - Set up WebSocket server and OpenAI Realtime connection?
2. **Start with Watch** - Implement audio recording first?
3. **Create a prototype** - Minimal working version to test?

Let me know and I'll begin!



