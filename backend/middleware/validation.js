const { sendError, ErrorCodes } = require('../utils/errors');

/**
 * Middleware to validate Apple ID token in request body
 */
function validateAppleIDToken(req, res, next) {
    const { appleIDToken } = req.body;
    
    if (!appleIDToken) {
        return sendError(res, 400, 'Apple ID token is required', ErrorCodes.MISSING_APPLE_ID_TOKEN);
    }
    
    if (typeof appleIDToken !== 'string') {
        return sendError(res, 400, 'Apple ID token must be a string', ErrorCodes.INVALID_APPLE_ID_TOKEN);
    }
    
    if (appleIDToken.trim().length === 0) {
        return sendError(res, 400, 'Apple ID token cannot be empty', ErrorCodes.INVALID_APPLE_ID_TOKEN);
    }
    
    // Basic JWT format validation (starts with "eyJ")
    if (!appleIDToken.startsWith('eyJ')) {
        return sendError(res, 400, 'Invalid Apple ID token format', ErrorCodes.INVALID_APPLE_ID_TOKEN);
    }
    
    next();
}

/**
 * Middleware to validate message in request body
 */
function validateMessage(req, res, next) {
    const { message } = req.body;
    
    if (!message) {
        return sendError(res, 400, 'Message is required', ErrorCodes.MISSING_INPUT);
    }
    
    if (typeof message !== 'string') {
        return sendError(res, 400, 'Message must be a string', ErrorCodes.INVALID_MESSAGE_FORMAT);
    }
    
    const trimmed = message.trim();
    
    if (trimmed.length === 0) {
        return sendError(res, 400, 'Message cannot be empty', ErrorCodes.EMPTY_MESSAGE);
    }
    
    if (trimmed.length > 5000) {
        return sendError(res, 400, 'Message exceeds maximum length of 5000 characters', ErrorCodes.MESSAGE_TOO_LONG);
    }
    
    next();
}

/**
 * Middleware to validate conversation array in request body
 */
function validateConversation(req, res, next) {
    const { conversation } = req.body;
    
    // Conversation is optional, but if provided, it must be valid
    if (conversation !== undefined) {
        if (!Array.isArray(conversation)) {
            return sendError(res, 400, 'Conversation must be an array', ErrorCodes.INVALID_CONVERSATION_FORMAT);
        }
        
        // Validate each message in the conversation
        for (let i = 0; i < conversation.length; i++) {
            const msg = conversation[i];
            
            if (!msg || typeof msg !== 'object') {
                return sendError(res, 400, `Conversation message at index ${i} must be an object`, ErrorCodes.INVALID_MESSAGE_FORMAT);
            }
            
            if (!msg.role || typeof msg.role !== 'string') {
                return sendError(res, 400, `Conversation message at index ${i} must have a valid role`, ErrorCodes.INVALID_MESSAGE_ROLE);
            }
            
            if (msg.role !== 'user' && msg.role !== 'assistant') {
                return sendError(res, 400, `Conversation message at index ${i} must have role 'user' or 'assistant'`, ErrorCodes.INVALID_MESSAGE_ROLE);
            }
            
            if (!msg.content || typeof msg.content !== 'string') {
                return sendError(res, 400, `Conversation message at index ${i} must have valid content`, ErrorCodes.INVALID_MESSAGE_CONTENT);
            }
            
            if (msg.content.trim().length === 0) {
                return sendError(res, 400, `Conversation message at index ${i} content cannot be empty`, ErrorCodes.EMPTY_MESSAGE_CONTENT);
            }
        }
    }
    
    next();
}

module.exports = {
    validateAppleIDToken,
    validateMessage,
    validateConversation
};

