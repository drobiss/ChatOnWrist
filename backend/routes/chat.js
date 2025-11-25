const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');
const { getDatabase } = require('../database/init');
const { validateMessage, validateConversation } = require('../middleware/validation');
const { sendError, ErrorCodes } = require('../utils/errors');

const router = express.Router();

// Test endpoint (no auth required)
const baseSystemPrompt = `You are ChatOnWrist, a concise, context-aware AI assistant. 
- Always keep the conversation history in mind and treat follow-up questions as referring to the most recent topic unless the user clearly switches subjects.
- Answer in the language the user uses.
- Provide a direct answer first. Add short supporting context only if it helps understanding.`;

router.post('/test', validateConversation, async (req, res) => {
    const requestId = Date.now() + '-' + Math.random().toString(36).substr(2, 9);
    try {
        const { message, conversation } = req.body;
        
        console.log(`[${requestId}] 📥 Received test chat request:`);
        console.log(`[${requestId}]   Message:`, message);
        console.log(`[${requestId}]   Conversation type:`, Array.isArray(conversation) ? 'array' : typeof conversation);
        console.log(`[${requestId}]   Conversation length:`, Array.isArray(conversation) ? conversation.length : 'N/A');
        
        // Validate that either message or conversation is provided
        if ((!message || message.trim().length === 0) && (!Array.isArray(conversation) || conversation.length === 0)) {
            return res.status(400).json({ 
                message: 'Message or conversation history is required',
                code: 'MISSING_INPUT'
            });
        }
        
        // If message is provided, validate it
        if (message) {
            const trimmed = message.trim();
            if (trimmed.length === 0) {
                return res.status(400).json({
                    message: 'Message cannot be empty',
                    code: 'EMPTY_MESSAGE'
                });
            }
            if (trimmed.length > 5000) {
                return res.status(400).json({
                    message: 'Message exceeds maximum length of 5000 characters',
                    code: 'MESSAGE_TOO_LONG'
                });
            }
        }
        
        const configuredTemperature = parseFloat(process.env.OPENAI_TEMPERATURE);
        const temperature = Number.isFinite(configuredTemperature) ? configuredTemperature : 0.3;
        const configuredMaxTokens = parseInt(process.env.OPENAI_MAX_TOKENS, 10);
        const maxTokens = Number.isInteger(configuredMaxTokens) ? configuredMaxTokens : 200;

        const conversationMessages = Array.isArray(conversation) ? conversation : [];
        
        console.log(`[${requestId}] 📋 Processing conversation history:`);
        conversationMessages.forEach((msg, idx) => {
            console.log(`[${requestId}]   [${idx}] ${msg.role}: ${msg.content?.substring(0, 50)}...`);
        });
        
        // Build messages array: system prompt + conversation history + new message (if provided)
        const messages = [
            { role: 'system', content: baseSystemPrompt },
            ...conversationMessages
                .filter(msg => msg && typeof msg.content === 'string' && typeof msg.role === 'string')
                .map(msg => ({
                    role: msg.role === 'assistant' ? 'assistant' : 'user',
                    content: msg.content
                }))
        ];
        
        // Always add the message parameter if provided (it's the new user input)
        const newUserMessage = message && message.trim().length > 0 ? message.trim() : null;
        if (newUserMessage) {
            messages.push({ role: 'user', content: newUserMessage });
        }
        
        console.log(`[${requestId}] 📤 Sending to OpenAI with ${messages.length} messages total`);
        console.log(`[${requestId}]   New message:`, newUserMessage);
        console.log(`[${requestId}] 📤 Full messages array being sent to OpenAI:`);
        messages.forEach((msg, idx) => {
            console.log(`[${requestId}]   [${idx}] ${msg.role}: ${msg.content?.substring(0, 80)}...`);
        });

        const openaiResponse = await axios.post('https://api.openai.com/v1/chat/completions', {
            model: process.env.OPENAI_MODEL || 'gpt-4o',
            messages,
            max_tokens: maxTokens,
            temperature
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });
        
        const aiResponse = openaiResponse.data.choices[0].message.content;
        console.log(`[${requestId}] ✅ OpenAI response received:`, aiResponse.substring(0, 100) + '...');
        console.log(`[${requestId}] ✅ Full response length:`, aiResponse.length);
        
        res.json({
            response: aiResponse,
            conversationId: 'test-conversation',
            messageId: 'test-message'
        });
        
    } catch (error) {
        console.error(`[${requestId}] ❌ Test chat error:`, error);
        if (error.response) {
            console.error(`[${requestId}]   OpenAI API error:`, error.response.status, error.response.data);
        }
        sendError(res, 500, 'Failed to process message', ErrorCodes.CHAT_ERROR, error.message);
    }
});

// Middleware to verify device token
const verifyDeviceToken = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                message: 'Authorization token required',
                code: 'MISSING_TOKEN'
            });
        }

        const token = authHeader.substring(7);
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        if (decoded.type !== 'device') {
            return sendError(res, 401, 'Invalid token type', ErrorCodes.INVALID_TOKEN_TYPE);
        }

        req.deviceId = decoded.deviceId;
        req.userId = decoded.userId;
        next();
    } catch (error) {
        sendError(res, 401, 'Invalid token', ErrorCodes.INVALID_TOKEN);
    }
};

// POST /chat/message - Send a message and get AI response
router.post('/message', verifyDeviceToken, validateMessage, async (req, res) => {
    try {
        const { message, conversationId } = req.body;
        
        // Validate conversationId format if provided
        if (conversationId && typeof conversationId !== 'string') {
            return res.status(400).json({
                message: 'Invalid conversation ID format',
                code: 'INVALID_CONVERSATION_ID'
            });
        }

        const db = getDatabase();
        let currentConversationId = conversationId;

        // If no conversation ID provided, create a new conversation
        if (!currentConversationId) {
            currentConversationId = uuidv4();
            const title = message.length > 50 ? message.substring(0, 50) + '...' : message;
            
            await new Promise((resolve, reject) => {
                db.run(
                    'INSERT INTO conversations (id, device_id, title) VALUES (?, ?, ?)',
                    [currentConversationId, req.deviceId, title],
                    (err) => {
                        if (err) reject(err);
                        else resolve();
                    }
                );
            });
        }

        // Save user message
        const userMessageId = uuidv4();
        await new Promise((resolve, reject) => {
            db.run(
                'INSERT INTO messages (id, conversation_id, content, is_from_user) VALUES (?, ?, ?, ?)',
                [userMessageId, currentConversationId, message, true],
                (err) => {
                    if (err) reject(err);
                    else resolve();
                }
            );
        });

        // Get conversation history for context
        const conversationHistory = await new Promise((resolve, reject) => {
            db.all(
                `SELECT content, is_from_user FROM messages 
                 WHERE conversation_id = ? 
                 ORDER BY created_at ASC 
                 LIMIT 20`,
                [currentConversationId],
                (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                }
            );
        });

        // Prepare messages for OpenAI
        const messages = [
            {
                role: 'system',
                content: baseSystemPrompt
            },
            ...conversationHistory.map(msg => ({
                role: msg.is_from_user ? 'user' : 'assistant',
                content: msg.content
            }))
        ];

        // Call OpenAI API
        const configuredTemperature = parseFloat(process.env.OPENAI_TEMPERATURE);
        const temperature = Number.isFinite(configuredTemperature) ? configuredTemperature : 0.3;
        const configuredMaxTokens = parseInt(process.env.OPENAI_MAX_TOKENS, 10);
        const maxTokens = Number.isInteger(configuredMaxTokens) ? configuredMaxTokens : 200;

        const openaiResponse = await axios.post('https://api.openai.com/v1/chat/completions', {
            model: process.env.OPENAI_MODEL || 'gpt-4o',
            messages: messages,
            max_tokens: maxTokens,
            temperature
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        const aiResponse = openaiResponse.data.choices[0].message.content;

        // Save AI response
        const aiMessageId = uuidv4();
        await new Promise((resolve, reject) => {
            db.run(
                'INSERT INTO messages (id, conversation_id, content, is_from_user) VALUES (?, ?, ?, ?)',
                [aiMessageId, currentConversationId, aiResponse, false],
                (err) => {
                    if (err) reject(err);
                    else resolve();
                }
            );
        });

        // Update conversation timestamp
        await new Promise((resolve, reject) => {
            db.run(
                'UPDATE conversations SET updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                [currentConversationId],
                (err) => {
                    if (err) reject(err);
                    else resolve();
                }
            );
        });

        res.json({
            response: aiResponse,
            conversationId: currentConversationId,
            messageId: aiMessageId
        });

    } catch (error) {
        console.error('Chat message error:', error);
        
        if (error.response?.status === 401) {
            sendError(res, 500, 'OpenAI API key is invalid', ErrorCodes.OPENAI_AUTH_ERROR);
        } else if (error.response?.status === 429) {
            sendError(res, 500, 'OpenAI API rate limit exceeded', ErrorCodes.OPENAI_RATE_LIMIT);
        } else {
            sendError(res, 500, 'Failed to process message', ErrorCodes.CHAT_ERROR, error.message);
        }
    }
});

// GET /chat/conversations - Get all conversations for the device
router.get('/conversations', verifyDeviceToken, async (req, res) => {
    try {
        const db = getDatabase();
        
        const conversations = await new Promise((resolve, reject) => {
            db.all(
                `SELECT c.id, c.title, c.created_at, c.updated_at,
                        (SELECT content FROM messages 
                         WHERE conversation_id = c.id 
                         ORDER BY created_at DESC LIMIT 1) as last_message
                 FROM conversations c 
                 WHERE c.device_id = ? 
                 ORDER BY c.updated_at DESC`,
                [req.deviceId],
                (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                }
            );
        });

        // Get messages for each conversation
        const conversationsWithMessages = await Promise.all(
            conversations.map(async (conv) => {
                const messages = await new Promise((resolve, reject) => {
                    db.all(
                        `SELECT id, content, is_from_user, created_at as timestamp
                         FROM messages 
                         WHERE conversation_id = ? 
                         ORDER BY created_at ASC`,
                        [conv.id],
                        (err, rows) => {
                            if (err) reject(err);
                            else resolve(rows);
                        }
                    );
                });

                return {
                    id: conv.id,
                    title: conv.title,
                    lastMessage: conv.last_message || '',
                    createdAt: conv.created_at,
                    updatedAt: conv.updated_at,
                    messages: messages
                };
            })
        );

        res.json(conversationsWithMessages);

    } catch (error) {
        console.error('Get conversations error:', error);
        sendError(res, 500, 'Failed to get conversations', ErrorCodes.DATABASE_ERROR, error.message);
    }
});

// GET /chat/conversations/:id - Get a specific conversation
router.get('/conversations/:id', verifyDeviceToken, async (req, res) => {
    try {
        const { id } = req.params;
        const db = getDatabase();
        
        // Verify conversation belongs to this device
        const conversation = await new Promise((resolve, reject) => {
            db.get(
                'SELECT * FROM conversations WHERE id = ? AND device_id = ?',
                [id, req.deviceId],
                (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                }
            );
        });

        if (!conversation) {
            return sendError(res, 404, 'Conversation not found', ErrorCodes.CONVERSATION_NOT_FOUND);
        }

        // Get messages
        const messages = await new Promise((resolve, reject) => {
            db.all(
                `SELECT id, content, is_from_user, created_at as timestamp
                 FROM messages 
                 WHERE conversation_id = ? 
                 ORDER BY created_at ASC`,
                [id],
                (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                }
            );
        });

        res.json({
            id: conversation.id,
            title: conversation.title,
            lastMessage: messages.length > 0 ? messages[messages.length - 1].content : '',
            createdAt: conversation.created_at,
            updatedAt: conversation.updated_at,
            messages: messages
        });

    } catch (error) {
        console.error('Get conversation error:', error);
        sendError(res, 500, 'Failed to get conversation', ErrorCodes.DATABASE_ERROR, error.message);
    }
});

module.exports = router;
