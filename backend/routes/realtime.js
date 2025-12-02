const WebSocket = require('ws');
const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const axios = require('axios');

/**
 * WebSocket server for real-time voice chat with OpenAI Realtime API
 * 
 * Flow:
 * Watch App (audio) → Backend WebSocket → OpenAI Realtime API
 * OpenAI Realtime API (audio) → Backend WebSocket → Watch App
 */

// Store active connections
const activeConnections = new Map();

/**
 * Create WebSocket server for real-time voice chat
 * @param {http.Server} server - HTTP server instance
 */
function createRealtimeServer(server) {
    const wss = new WebSocketServer({ 
        server,
        path: '/realtime'
    });

    wss.on('connection', (ws, req) => {
        console.log('🔌 New WebSocket connection from:', req.socket.remoteAddress);
        
        let watchId = null;
        let openaiWS = null;
        let conversationId = null;
        
        // Authenticate connection
        const token = new URL(req.url, 'http://localhost').searchParams.get('token');
        if (!token) {
            console.error('❌ No token provided in WebSocket connection');
            ws.close(1008, 'Authentication required');
            return;
        }

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            if (decoded.type !== 'device') {
                throw new Error('Invalid token type');
            }
            watchId = decoded.deviceId;
            console.log('✅ Authenticated WebSocket connection for device:', watchId);
        } catch (error) {
            console.error('❌ WebSocket authentication failed:', error.message);
            ws.close(1008, 'Invalid token');
            return;
        }

        // Handle messages from Watch
        ws.on('message', async (data) => {
            try {
                const message = JSON.parse(data.toString());
                
                switch (message.type) {
                    case 'start_conversation':
                        await handleStartConversation(ws, message, watchId);
                        break;
                    
                    case 'audio_chunk':
                        await handleAudioChunk(ws, message, openaiWS);
                        break;
                    
                    case 'end_conversation':
                        await handleEndConversation(ws, openaiWS);
                        break;
                    
                    default:
                        console.warn('⚠️ Unknown message type:', message.type);
                }
            } catch (error) {
                // Handle binary audio data
                if (Buffer.isBuffer(data)) {
                    await handleBinaryAudio(data, openaiWS);
                } else {
                    console.error('❌ Error processing WebSocket message:', error);
                    ws.send(JSON.stringify({
                        type: 'error',
                        message: error.message
                    }));
                }
            }
        });

        // Handle start conversation
        async function handleStartConversation(ws, message, deviceId) {
            try {
                conversationId = message.conversationId || `conv-${Date.now()}`;
                console.log(`🎙️ Starting conversation ${conversationId} for device ${deviceId}`);

                // Connect to OpenAI Realtime API
                const openaiApiKey = process.env.OPENAI_API_KEY;
                if (!openaiApiKey) {
                    throw new Error('OPENAI_API_KEY not configured');
                }

                // Create OpenAI Realtime WebSocket connection
                const openaiUrl = 'wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17';
                openaiWS = new WebSocket(openaiUrl, {
                    headers: {
                        'Authorization': `Bearer ${openaiApiKey}`,
                        'OpenAI-Beta': 'realtime=v1'
                    }
                });

                // Handle OpenAI connection open
                openaiWS.on('open', () => {
                    console.log('✅ Connected to OpenAI Realtime API');
                    
                    // Send session configuration
                    // OpenAI Realtime API expects session.update as first message
                    const sessionConfig = {
                        type: 'session.update',
                        session: {
                            modalities: ['text', 'audio'],
                            instructions: 'You are ChatOnWrist, a concise, context-aware AI assistant. Answer in the language the user uses. Keep responses conversational and natural.',
                            voice: 'alloy', // Options: 'alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'
                            input_audio_format: 'pcm16', // 16-bit PCM
                            output_audio_format: 'pcm16',
                            input_audio_transcription: {
                                model: 'whisper-1'
                            },
                            turn_detection: {
                                type: 'server_vad', // Server-side voice activity detection
                                threshold: 0.5,
                                prefix_padding_ms: 300,
                                silence_duration_ms: 500
                            },
                            temperature: 0.8,
                            max_response_output_tokens: 4096
                        }
                    };
                    
                    openaiWS.send(JSON.stringify(sessionConfig));
                    console.log('📤 Sent session configuration to OpenAI');

                    // Send conversation history if provided (after session update)
                    // Wait a bit for session to be ready
                    setTimeout(() => {
                        if (message.conversationHistory && Array.isArray(message.conversationHistory)) {
                            const historyMessages = message.conversationHistory
                                .slice(-10) // Last 10 messages
                                .map(msg => ({
                                    type: 'conversation.item.create',
                                    item: {
                                        type: 'message',
                                        role: msg.role === 'user' ? 'user' : 'assistant',
                                        content: [
                                            {
                                                type: 'input_text',
                                                text: msg.content
                                            }
                                        ]
                                    }
                                }));

                            historyMessages.forEach(msg => {
                                if (openaiWS && openaiWS.readyState === WebSocket.OPEN) {
                                    openaiWS.send(JSON.stringify(msg));
                                }
                            });
                            console.log(`📤 Sent ${historyMessages.length} history messages to OpenAI`);
                        }
                    }, 500);

                    ws.send(JSON.stringify({
                        type: 'conversation_started',
                        conversationId: conversationId
                    }));
                });

                // Handle messages from OpenAI
                openaiWS.on('message', (data) => {
                    try {
                        const message = JSON.parse(data.toString());
                        
                        switch (message.type) {
                            case 'session.created':
                                console.log('✅ OpenAI session created');
                                break;
                            
                            case 'session.updated':
                                console.log('✅ OpenAI session updated');
                                break;
                            
                            case 'input_audio_buffer.speech_started':
                                console.log('🎤 OpenAI detected speech start');
                                ws.send(JSON.stringify({
                                    type: 'speech_started',
                                    conversationId: conversationId
                                }));
                                break;
                            
                            case 'input_audio_buffer.speech_stopped':
                                console.log('🎤 OpenAI detected speech stop');
                                ws.send(JSON.stringify({
                                    type: 'speech_stopped',
                                    conversationId: conversationId
                                }));
                                break;
                            
                            case 'response.audio_transcript.delta':
                                // Forward transcript delta to Watch (optional, for UI display)
                                if (message.delta) {
                                    ws.send(JSON.stringify({
                                        type: 'transcript_delta',
                                        text: message.delta,
                                        conversationId: conversationId
                                    }));
                                }
                                break;
                            
                            case 'response.audio_transcript.done':
                                // Final transcript
                                ws.send(JSON.stringify({
                                    type: 'transcript_complete',
                                    text: message.text,
                                    conversationId: conversationId
                                }));
                                break;
                            
                            case 'response.audio.delta':
                                // Forward audio chunk to Watch
                                if (message.delta) {
                                    ws.send(JSON.stringify({
                                        type: 'audio_response',
                                        data: message.delta, // Base64 encoded audio
                                        conversationId: conversationId
                                    }));
                                }
                                break;
                            
                            case 'response.done':
                                // Response complete
                                console.log('✅ OpenAI response complete');
                                ws.send(JSON.stringify({
                                    type: 'response_complete',
                                    conversationId: conversationId
                                }));
                                break;
                            
                            case 'error':
                                console.error('❌ OpenAI Realtime error:', message);
                                ws.send(JSON.stringify({
                                    type: 'error',
                                    message: message.error?.message || 'OpenAI API error',
                                    conversationId: conversationId
                                }));
                                break;
                            
                            default:
                                // Log other message types for debugging
                                if (process.env.NODE_ENV === 'development') {
                                    console.log('📨 OpenAI message type:', message.type);
                                }
                        }
                    } catch (error) {
                        // Handle binary audio data from OpenAI
                        if (Buffer.isBuffer(data)) {
                            // Convert binary audio to base64 and forward
                            ws.send(JSON.stringify({
                                type: 'audio_response',
                                data: data.toString('base64'),
                                conversationId: conversationId
                            }));
                        } else {
                            console.error('❌ Error processing OpenAI message:', error);
                        }
                    }
                });

                openaiWS.on('error', (error) => {
                    console.error('❌ OpenAI WebSocket error:', error);
                    ws.send(JSON.stringify({
                        type: 'error',
                        message: 'OpenAI connection error',
                        conversationId: conversationId
                    }));
                });

                openaiWS.on('close', () => {
                    console.log('🔌 OpenAI WebSocket closed');
                    ws.send(JSON.stringify({
                        type: 'conversation_ended',
                        conversationId: conversationId
                    }));
                });

            } catch (error) {
                console.error('❌ Error starting conversation:', error);
                ws.send(JSON.stringify({
                    type: 'error',
                    message: error.message,
                    conversationId: conversationId
                }));
            }
        }

        // Handle audio chunk from Watch
        async function handleAudioChunk(ws, message, openaiWS) {
            if (!openaiWS || openaiWS.readyState !== WebSocket.OPEN) {
                console.warn('⚠️ OpenAI WebSocket not ready, ignoring audio chunk');
                return;
            }

            try {
                // Send audio to OpenAI using input_audio_buffer.append
                // OpenAI Realtime API expects audio to be sent via input_audio_buffer.append message
                if (message.data) {
                    // Base64 encoded audio
                    const audioMessage = {
                        type: 'input_audio_buffer.append',
                        audio: message.data // Base64 encoded PCM16 audio
                    };
                    openaiWS.send(JSON.stringify(audioMessage));
                } else if (message.audio) {
                    // Direct audio field
                    const audioMessage = {
                        type: 'input_audio_buffer.append',
                        audio: message.audio
                    };
                    openaiWS.send(JSON.stringify(audioMessage));
                } else {
                    console.warn('⚠️ Audio chunk missing data');
                }
            } catch (error) {
                console.error('❌ Error forwarding audio chunk:', error);
            }
        }

        // Handle binary audio data
        async function handleBinaryAudio(data, openaiWS) {
            if (!openaiWS || openaiWS.readyState !== WebSocket.OPEN) {
                return;
            }

            try {
                // Convert binary audio to base64 and send via input_audio_buffer.append
                const base64Audio = data.toString('base64');
                const audioMessage = {
                    type: 'input_audio_buffer.append',
                    audio: base64Audio
                };
                openaiWS.send(JSON.stringify(audioMessage));
            } catch (error) {
                console.error('❌ Error forwarding binary audio:', error);
            }
        }

        // Handle end conversation
        async function handleEndConversation(ws, openaiWS) {
            console.log('🔚 Ending conversation');
            
            if (openaiWS && openaiWS.readyState === WebSocket.OPEN) {
                // Commit the input audio buffer (finalize any pending audio)
                openaiWS.send(JSON.stringify({
                    type: 'input_audio_buffer.commit'
                }));
                
                // Request final response if needed
                openaiWS.send(JSON.stringify({
                    type: 'response.create',
                    response: {
                        modalities: ['audio']
                    }
                }));
                
                // Close OpenAI connection after a delay
                setTimeout(() => {
                    if (openaiWS) {
                        openaiWS.close();
                    }
                }, 2000);
            }

            ws.send(JSON.stringify({
                type: 'conversation_ended',
                conversationId: conversationId
            }));
        }

        // Handle Watch disconnection
        ws.on('close', () => {
            console.log('🔌 Watch WebSocket disconnected');
            
            if (openaiWS && openaiWS.readyState === WebSocket.OPEN) {
                openaiWS.close();
            }
            
            if (watchId) {
                activeConnections.delete(watchId);
            }
        });

        ws.on('error', (error) => {
            console.error('❌ Watch WebSocket error:', error);
        });

        // Store connection
        if (watchId) {
            activeConnections.set(watchId, { ws, openaiWS, conversationId });
        }
    });

    wss.on('error', (error) => {
        console.error('❌ WebSocket server error:', error);
    });

    console.log('✅ Realtime WebSocket server started on /realtime');
    return wss;
}

module.exports = {
    createRealtimeServer
};

