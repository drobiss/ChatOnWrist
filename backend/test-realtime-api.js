#!/usr/bin/env node

/**
 * Test script to verify OpenAI Realtime API access
 * Usage: node test-realtime-api.js [your-api-key]
 */

require('dotenv').config();
const WebSocket = require('ws');

const apiKey = process.argv[2] || process.env.OPENAI_API_KEY;

if (!apiKey) {
    console.error('❌ No API key provided');
    console.error('Usage: node test-realtime-api.js [your-api-key]');
    console.error('Or set OPENAI_API_KEY in .env file');
    process.exit(1);
}

console.log('🔌 Testing OpenAI Realtime API connection...');
console.log('📝 API Key:', apiKey.substring(0, 10) + '...' + apiKey.substring(apiKey.length - 4));

const model = process.env.OPENAI_REALTIME_MODEL || 'gpt-4o-realtime-preview-2024-12-17';
const url = `wss://api.openai.com/v1/realtime?model=${model}`;

console.log('🌐 Connecting to:', url);

console.log('⏳ Attempting WebSocket connection...');

const ws = new WebSocket(url, {
    headers: {
        'Authorization': `Bearer ${apiKey}`,
        'OpenAI-Beta': 'realtime=v1'
    }
});

let sessionCreated = false;
let testCompleted = false;
let connectionOpened = false;

// Track connection state
ws.on('open', () => {
    connectionOpened = true;
});

// Check connection state periodically
const connectionCheck = setInterval(() => {
    if (ws.readyState === WebSocket.CONNECTING) {
        console.log('⏳ Still connecting...');
    } else if (ws.readyState === WebSocket.OPEN) {
        console.log('✅ Connection is OPEN');
        clearInterval(connectionCheck);
    } else if (ws.readyState === WebSocket.CLOSED || ws.readyState === WebSocket.CLOSING) {
        console.log('❌ Connection is CLOSED/CLOSING');
        clearInterval(connectionCheck);
    }
}, 1000);

ws.on('open', () => {
    connectionOpened = true;
    clearInterval(connectionCheck);
    console.log('✅ WebSocket connection opened');
    console.log('📡 Connection state: OPEN');
    
    // Send session configuration
    const sessionConfig = {
        type: 'session.update',
        session: {
            modalities: ['text', 'audio'],
            instructions: 'You are a test assistant. Say "Hello, Realtime API is working!"',
            voice: 'alloy',
            input_audio_format: 'pcm16',
            output_audio_format: 'pcm16',
            turn_detection: {
                type: 'server_vad',
                threshold: 0.5,
                prefix_padding_ms: 300,
                silence_duration_ms: 500
            }
        }
    };
    
    console.log('📤 Sending session configuration...');
    ws.send(JSON.stringify(sessionConfig));
});

ws.on('message', (data) => {
    try {
        const message = JSON.parse(data.toString());
        console.log('📨 Received message type:', message.type);
        
        switch (message.type) {
            case 'session.created':
                console.log('✅ Session created');
                sessionCreated = true;
                break;
                
            case 'session.updated':
                console.log('✅ Session updated');
                if (!testCompleted) {
                    console.log('\n🎉 SUCCESS! Your API key has access to Realtime API');
                    console.log('✅ You can now use real-time voice chat');
                    testCompleted = true;
                    
                    // Close connection after successful test
                    setTimeout(() => {
                        ws.close();
                        process.exit(0);
                    }, 1000);
                }
                break;
                
            case 'error':
                console.error('❌ Error from OpenAI:', JSON.stringify(message.error, null, 2));
                if (message.error?.message) {
                    console.error('   Error message:', message.error.message);
                }
                ws.close();
                process.exit(1);
                break;
                
            default:
                // Log other message types for debugging
                if (process.env.DEBUG) {
                    console.log('   Message:', JSON.stringify(message, null, 2));
                }
                break;
        }
    } catch (error) {
        // Handle binary data or other formats
        console.log('📦 Received non-JSON message (likely binary audio data)');
        console.log('   Length:', data.length, 'bytes');
    }
});

ws.on('error', (error) => {
    console.error('❌ WebSocket error:', error.message);
    console.error('   Full error:', error);
    
    if (error.message && (error.message.includes('401') || error.message.includes('Unauthorized'))) {
        console.error('\n❌ Authentication failed!');
        console.error('   - Check that your API key is correct');
        console.error('   - Make sure your API key has access to Realtime API');
    } else if (error.message && (error.message.includes('403') || error.message.includes('Forbidden'))) {
        console.error('\n❌ Access forbidden!');
        console.error('   - Your API key may not have access to Realtime API');
        console.error('   - Check your OpenAI account/billing status');
    } else {
        console.error('\n❌ Connection failed!');
        console.error('   - Check your internet connection');
        console.error('   - Verify the API endpoint is accessible');
        console.error('   - Make sure your API key is valid');
    }
    
    process.exit(1);
});

ws.on('close', (code, reason) => {
    if (!testCompleted && code !== 1000) {
        console.error(`\n❌ Connection closed unexpectedly (code: ${code})`);
        if (reason) {
            console.error('   Reason:', reason.toString());
        }
        process.exit(1);
    }
});

// Timeout after 15 seconds
setTimeout(() => {
    if (!testCompleted) {
        clearInterval(connectionCheck);
        console.error('\n❌ Test timed out');
        console.error('   Connection state:', ws.readyState === WebSocket.CONNECTING ? 'CONNECTING' : 
                                         ws.readyState === WebSocket.OPEN ? 'OPEN' :
                                         ws.readyState === WebSocket.CLOSING ? 'CLOSING' :
                                         ws.readyState === WebSocket.CLOSED ? 'CLOSED' : 'UNKNOWN');
        console.error('   Connection opened:', connectionOpened);
        console.error('\n   Possible issues:');
        console.error('     1. Your API key does not have access to Realtime API (most likely)');
        console.error('     2. Network/firewall is blocking the WebSocket connection');
        console.error('     3. OpenAI API is experiencing issues');
        console.error('\n   Troubleshooting steps:');
        console.error('   ✅ Verify your API key at https://platform.openai.com/api-keys');
        console.error('   ✅ Check if Realtime API is available in your region');
        console.error('   ✅ Ensure you have billing enabled on your OpenAI account');
        console.error('   ✅ Make sure your API key has access to beta features');
        console.error('   ✅ Try creating a new API key if needed');
        console.error('\n   Note: Realtime API is a beta feature and may require:');
        console.error('   - Active billing account');
        console.error('   - API key with beta access enabled');
        console.error('   - Account approval for beta features');
        if (ws.readyState === WebSocket.CONNECTING || ws.readyState === WebSocket.OPEN) {
            ws.close();
        }
        process.exit(1);
    }
}, 15000);


