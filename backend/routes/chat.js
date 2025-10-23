const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');
const { getDatabase } = require('../database/init');

const router = express.Router();

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
            return res.status(401).json({
                message: 'Invalid token type',
                code: 'INVALID_TOKEN_TYPE'
            });
        }

        req.deviceId = decoded.deviceId;
        req.userId = decoded.userId;
        next();
    } catch (error) {
        res.status(401).json({
            message: 'Invalid token',
            code: 'INVALID_TOKEN'
        });
    }
};

// POST /chat/message - Send a message and get AI response
router.post('/message', verifyDeviceToken, async (req, res) => {
    try {
        const { message, conversationId } = req.body;
        
        if (!message || message.trim().length === 0) {
            return res.status(400).json({
                message: 'Message content is required',
                code: 'MISSING_MESSAGE'
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
        const messages = conversationHistory.map(msg => ({
            role: msg.is_from_user ? 'user' : 'assistant',
            content: msg.content
        }));

        // Add the new user message
        messages.push({
            role: 'user',
            content: message
        });

        // Call OpenAI API
        const openaiResponse = await axios.post('https://api.openai.com/v1/chat/completions', {
            model: process.env.OPENAI_MODEL || 'gpt-4o',
            messages: messages,
            max_tokens: parseInt(process.env.OPENAI_MAX_TOKENS) || 150,
            temperature: parseFloat(process.env.OPENAI_TEMPERATURE) || 0.7
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
            res.status(500).json({
                message: 'OpenAI API key is invalid',
                code: 'OPENAI_AUTH_ERROR'
            });
        } else if (error.response?.status === 429) {
            res.status(500).json({
                message: 'OpenAI API rate limit exceeded',
                code: 'OPENAI_RATE_LIMIT'
            });
        } else {
            res.status(500).json({
                message: 'Failed to process message',
                code: 'CHAT_ERROR'
            });
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
        res.status(500).json({
            message: 'Failed to get conversations',
            code: 'GET_CONVERSATIONS_ERROR'
        });
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
            return res.status(404).json({
                message: 'Conversation not found',
                code: 'CONVERSATION_NOT_FOUND'
            });
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
        res.status(500).json({
            message: 'Failed to get conversation',
            code: 'GET_CONVERSATION_ERROR'
        });
    }
});

module.exports = router;
