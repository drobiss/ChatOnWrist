# Backend HTTP Streaming API for watchOS

This document describes the HTTP streaming endpoints needed for the Watch app to work standalone (WebSocket alternative).

## Why HTTP Streaming?

watchOS blocks direct WebSocket connections due to NECP (Network Extension Control Policy) restrictions. HTTP streaming provides real-time communication that works on watchOS.

## Required Endpoints

### 1. Download Stream (Receive AI Responses)

**Endpoint:** `GET /realtime/stream`

**Query Parameters:**
- `token` (required): Device token for authentication
- `conversationId` (required): UUID of the conversation
- `history` (optional): Base64-encoded JSON array of conversation history

**Response Format:** Server-Sent Events (SSE)

**Content-Type:** `text/event-stream`

**Events to Send:**

```
event: conversation_started
data: {"conversationId": "uuid"}

event: audio_response
data: <base64-encoded-audio-pcm16-24khz>

event: transcript_delta
data: <partial-transcript-text>

event: transcript_complete
data: <complete-transcript-text>

event: response_complete
data: {}

event: conversation_ended
data: {}

event: error
data: <error-message>
```

**Example SSE Stream:**
```
event: conversation_started
data: {"conversationId": "123e4567-e89b-12d3-a456-426614174000"}

event: audio_response
data: SGVsbG8gd29ybGQ=

event: transcript_complete
data: Hello, how can I help you today?

event: response_complete
data: {}
```

**Implementation Notes:**
- Keep connection alive for duration of conversation
- Send audio chunks as they're generated (streaming)
- Use chunked transfer encoding
- Flush after each event to ensure immediate delivery
- Handle client disconnect gracefully

### 2. Upload Stream (Receive Audio from Watch)

**Endpoint:** `POST /realtime/upload`

**Query Parameters:**
- `token` (required): Device token for authentication
- `conversationId` (required): UUID of the conversation

**Request Headers:**
- `Content-Type: application/octet-stream`
- `Transfer-Encoding: chunked`

**Request Body:** 
- Streaming audio data (PCM16, 24kHz, mono)
- Audio sent in chunks as recorded
- No fixed content length (chunked encoding)

**Response:** 
- 200 OK when stream completes
- Keep connection open while receiving

**Implementation Notes:**
- Accept chunked transfer encoding
- Process audio chunks as they arrive (don't wait for full upload)
- Feed audio to OpenAI Realtime API in real-time
- Associate with conversation ID
- Handle connection drops gracefully

### 3. End Conversation

**Endpoint:** `POST /realtime/end`

**Query Parameters:**
- `token` (required): Device token for authentication
- `conversationId` (required): UUID of the conversation

**Response:** `200 OK`

**Implementation Notes:**
- Clean up resources for the conversation
- Close any open streams
- Send `conversation_ended` event to download stream

## Audio Format

**Specification:**
- **Sample Rate:** 24000 Hz (24 kHz)
- **Channels:** 1 (Mono)
- **Bit Depth:** 16-bit
- **Format:** PCM (Linear PCM, signed integer)
- **Byte Order:** Little-endian

This matches OpenAI Realtime API requirements.

## Authentication

Use the `token` query parameter for authentication. This should be the device token (JWT) containing:
- `deviceId`: UUID of the Watch device
- `userId`: UUID of the user
- `type`: "device"

Validate token on each request.

## Error Handling

**HTTP Status Codes:**
- `200 OK`: Success
- `401 Unauthorized`: Invalid or expired token
- `400 Bad Request`: Missing required parameters
- `500 Internal Server Error`: Server error

**SSE Error Event:**
```
event: error
data: <human-readable error message>
```

## Conversation History Format

The `history` query parameter should be a base64-encoded JSON array:

```json
[
  {
    "role": "user",
    "content": "Hello"
  },
  {
    "role": "assistant",
    "content": "Hi! How can I help you?"
  }
]
```

## Implementation Example (Node.js/Express)

```javascript
// Download stream endpoint
app.get('/realtime/stream', authenticateDevice, async (req, res) => {
  const { conversationId, history } = req.query;
  
  // Set up SSE
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  
  // Send conversation started
  res.write(`event: conversation_started\ndata: {"conversationId":"${conversationId}"}\n\n`);
  res.flush();
  
  // Set up OpenAI Realtime API connection
  // Stream responses back via SSE
  
  // Keep connection alive
  const keepAlive = setInterval(() => {
    res.write(': keepalive\n\n');
    res.flush();
  }, 15000);
  
  // Clean up on disconnect
  req.on('close', () => {
    clearInterval(keepAlive);
    // Close OpenAI connection
  });
});

// Upload stream endpoint
app.post('/realtime/upload', authenticateDevice, async (req, res) => {
  const { conversationId } = req.query;
  
  // Process incoming audio chunks
  req.on('data', (chunk) => {
    // Send audio chunk to OpenAI Realtime API
    processAudioChunk(conversationId, chunk);
  });
  
  req.on('end', () => {
    res.status(200).send('OK');
  });
  
  req.on('error', (error) => {
    console.error('Upload stream error:', error);
    res.status(500).send('Error');
  });
});
```

## Testing

**Test with curl:**

```bash
# Test download stream
curl -N "https://your-backend.com/realtime/stream?token=YOUR_TOKEN&conversationId=test-123"

# Test upload stream
curl -X POST \
  -H "Content-Type: application/octet-stream" \
  -H "Transfer-Encoding: chunked" \
  --data-binary @audio.pcm \
  "https://your-backend.com/realtime/upload?token=YOUR_TOKEN&conversationId=test-123"
```

## Performance Considerations

1. **Latency**: Keep it under 200ms for good UX
2. **Buffer Size**: Use small chunks (e.g., 4KB) for low latency
3. **Concurrency**: Handle multiple concurrent streams
4. **Timeouts**: Set reasonable timeouts (e.g., 5 minutes per conversation)
5. **Resource Cleanup**: Clean up when connections drop

## Fallback Strategy

The Watch app is configured to use HTTP streaming by default. If you want to support both:

1. Keep existing WebSocket endpoint for iPhone/iPad
2. Use HTTP streaming for watchOS only
3. Detect client type from User-Agent or explicit parameter

## Migration Path

1. Implement HTTP streaming endpoints alongside existing WebSocket
2. Test with Watch app
3. Once stable, consider using HTTP streaming for all platforms (optional)

## Security Notes

- Validate tokens on every request
- Rate limit by device/user
- Monitor for abuse
- Use HTTPS only
- Sanitize conversation IDs (UUIDs)

---

**Questions?** Open an issue or contact the backend team.

