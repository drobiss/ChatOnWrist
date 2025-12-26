const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const WebSocket = require('ws');

/**
 * HTTP Streaming routes for watchOS (WebSocket alternative)
 * 
 * These endpoints provide real-time voice chat using HTTP streaming
 * instead of WebSocket to avoid watchOS NECP restrictions.
 */

// Store active streaming sessions
const activeSessions = new Map();

/**
 * Middleware to authenticate device token
 */
function authenticateDevice(req, res, next) {
    const token = req.query.token || req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
        return res.status(401).json({ error: 'Authentication required' });
    }
    
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (decoded.type !== 'device') {
            return res.status(401).json({ error: 'Invalid token type' });
        }
        req.deviceId = decoded.deviceId;
        req.userId = decoded.userId;
        next();
    } catch (error) {
        console.error('Authentication error:', error);
        return res.status(401).json({ error: 'Invalid token' });
    }
}

/**
 * GET /realtime/stream
 * Server-Sent Events endpoint for receiving AI responses
 */
router.get('/stream', authenticateDevice, async (req, res) => {
    const { conversationId, history } = req.query;
    const deviceId = req.deviceId;
    
    console.log(`📥 Starting SSE stream for device ${deviceId}, conversation ${conversationId}`);
    
    // Set up Server-Sent Events
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('X-Accel-Buffering', 'no'); // Disable buffering for nginx
    res.flushHeaders();
    
    // Send initial event
    res.write(`event: conversation_started\n`);
    res.write(`data: {"conversationId":"${conversationId}"}\n\n`);
    
    // Parse conversation history
    let conversationHistory = [];
    if (history) {
        try {
            const historyBuffer = Buffer.from(history, 'base64');
            conversationHistory = JSON.parse(historyBuffer.toString('utf-8'));
        } catch (error) {
            console.error('Error parsing conversation history:', error);
        }
    }
    
    // Connect to OpenAI Realtime API
    let openaiWS = null;
    try {
        const openaiApiKey = process.env.OPENAI_API_KEY;
        if (!openaiApiKey) {
            throw new Error('OPENAI_API_KEY not configured');
        }
        
        const model = process.env.OPENAI_REALTIME_MODEL || 'gpt-4o-realtime-preview-2024-12-17';
        const openaiUrl = `wss://api.openai.com/v1/realtime?model=${model}`;
        
        openaiWS = new WebSocket(openaiUrl, {
            headers: {
                'Authorization': `Bearer ${openaiApiKey}`,
                'OpenAI-Beta': 'realtime=v1'
            }
        });
        
        // Handle OpenAI connection
        openaiWS.on('open', () => {
            console.log('✅ OpenAI connection opened for HTTP stream');
            
            // Configure session
            const sessionConfig = {
                type: 'session.update',
                session: {
                    modalities: ['text', 'audio'],
                    instructions: 'You are ChatOnWrist, a concise, context-aware AI assistant. Answer in the language the user uses. Keep responses conversational and natural.',
                    voice: 'alloy',
                    input_audio_format: 'pcm16',
                    output_audio_format: 'pcm16',
                    input_audio_transcription: {
                        model: 'whisper-1'
                    },
                    turn_detection: {
                        type: 'server_vad',
                        threshold: 0.5,
                        prefix_padding_ms: 300,
                        silence_duration_ms: 500
                    },
                    temperature: 0.8,
                    max_response_output_tokens: 4096
                }
            };
            
            openaiWS.send(JSON.stringify(sessionConfig));
            
            // Send conversation history after a delay
            if (conversationHistory.length > 0) {
                setTimeout(() => {
                    conversationHistory.slice(-10).forEach(msg => {
                        if (openaiWS && openaiWS.readyState === WebSocket.OPEN) {
                            openaiWS.send(JSON.stringify({
                                type: 'conversation.item.create',
                                item: {
                                    type: 'message',
                                    role: msg.role === 'user' ? 'user' : 'assistant',
                                    content: [{
                                        type: 'input_text',
                                        text: msg.content
                                    }]
                                }
                            }));
                        }
                    });
                }, 500);
            }
        });
        
        // Forward OpenAI messages to SSE stream
        openaiWS.on('message', (data) => {
            try {
                const message = JSON.parse(data.toString());
                
                switch (message.type) {
                    case 'session.created':
                    case 'session.updated':
                        console.log(`✅ OpenAI ${message.type}`);
                        break;
                    
                    case 'input_audio_buffer.speech_started':
                        res.write(`event: speech_started\n`);
                        res.write(`data: {}\n\n`);
                        break;
                    
                    case 'input_audio_buffer.speech_stopped':
                        res.write(`event: speech_stopped\n`);
                        res.write(`data: {}\n\n`);
                        break;
                    
                    case 'response.audio_transcript.delta':
                        if (message.delta) {
                            res.write(`event: transcript_delta\n`);
                            res.write(`data: ${message.delta}\n\n`);
                        }
                        break;
                    
                    case 'response.audio_transcript.done':
                        if (message.transcript) {
                            res.write(`event: transcript_complete\n`);
                            res.write(`data: ${message.transcript}\n\n`);
                        }
                        break;
                    
                    case 'response.audio.delta':
                        if (message.delta) {
                            res.write(`event: audio_response\n`);
                            res.write(`data: ${message.delta}\n\n`);
                        }
                        break;
                    
                    case 'response.done':
                        res.write(`event: response_complete\n`);
                        res.write(`data: {}\n\n`);
                        break;
                    
                    case 'error':
                        res.write(`event: error\n`);
                        res.write(`data: ${message.error?.message || 'OpenAI error'}\n\n`);
                        break;
                }
            } catch (error) {
                console.error('Error processing OpenAI message:', error);
            }
        });
        
        openaiWS.on('error', (error) => {
            console.error('❌ OpenAI WebSocket error:', error);
            res.write(`event: error\n`);
            res.write(`data: OpenAI connection error\n\n`);
        });
        
        openaiWS.on('close', () => {
            console.log('🔌 OpenAI connection closed');
            res.write(`event: conversation_ended\n`);
            res.write(`data: {}\n\n`);
            res.end();
        });
        
        // Store session
        activeSessions.set(conversationId, { openaiWS, res, deviceId });
        
    } catch (error) {
        console.error('Error setting up OpenAI connection:', error);
        res.write(`event: error\n`);
        res.write(`data: ${error.message}\n\n`);
        res.end();
        return;
    }
    
    // Keep connection alive
    const keepAlive = setInterval(() => {
        res.write(`: keepalive\n\n`);
    }, 15000);
    
    // Clean up on client disconnect
    req.on('close', () => {
        console.log('📥 SSE client disconnected');
        clearInterval(keepAlive);
        
        if (openaiWS && openaiWS.readyState === WebSocket.OPEN) {
            openaiWS.close();
        }
        
        activeSessions.delete(conversationId);
    });
});

/**
 * POST /realtime/upload
 * Receive audio chunks from Watch via HTTP streaming
 */
router.post('/upload', authenticateDevice, (req, res) => {
    const { conversationId } = req.query;
    const deviceId = req.deviceId;
    
    console.log(`📤 Starting audio upload stream for device ${deviceId}, conversation ${conversationId}`);
    
    // Get OpenAI WebSocket from active session
    const session = activeSessions.get(conversationId);
    if (!session || !session.openaiWS) {
        return res.status(400).json({ error: 'No active conversation session' });
    }
    
    const { openaiWS } = session;
    
    // Process incoming audio chunks
    req.on('data', (chunk) => {
        if (openaiWS && openaiWS.readyState === WebSocket.OPEN) {
            // Convert chunk to base64 and send to OpenAI
            const base64Audio = chunk.toString('base64');
            openaiWS.send(JSON.stringify({
                type: 'input_audio_buffer.append',
                audio: base64Audio
            }));
        }
    });
    
    req.on('end', () => {
        console.log('📤 Audio upload stream ended');
        res.status(200).send('OK');
    });
    
    req.on('error', (error) => {
        console.error('❌ Upload stream error:', error);
        res.status(500).send('Error');
    });
});

/**
 * POST /realtime/end
 * End a conversation session
 */
router.post('/end', authenticateDevice, (req, res) => {
    const { conversationId } = req.query;
    const deviceId = req.deviceId;
    
    console.log(`🔚 Ending conversation ${conversationId} for device ${deviceId}`);
    
    const session = activeSessions.get(conversationId);
    if (session) {
        const { openaiWS, res: sseRes } = session;
        
        if (openaiWS && openaiWS.readyState === WebSocket.OPEN) {
            // Commit audio buffer
            openaiWS.send(JSON.stringify({
                type: 'input_audio_buffer.commit'
            }));
            
            // Request final response
            openaiWS.send(JSON.stringify({
                type: 'response.create',
                response: {
                    modalities: ['audio']
                }
            }));
            
            // Close after delay
            setTimeout(() => {
                if (openaiWS) {
                    openaiWS.close();
                }
            }, 2000);
        }
        
        activeSessions.delete(conversationId);
    }
    
    res.status(200).json({ success: true });
});

module.exports = router;

