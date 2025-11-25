const { sendError, ErrorCodes } = require('../utils/errors');

/**
 * Validate Apple ID token in request body
 */
const validateAppleIDToken = (req, res, next) => {
    const { appleIDToken } = req.body;
    
    if (!appleIDToken || typeof appleIDToken !== 'string' || appleIDToken.trim().length === 0) {
        return sendError(res, 400, 'Apple ID token is required', ErrorCodes.VALIDATION_ERROR, 'MISSING_APPLE_ID_TOKEN');
    }
    
    // Basic JWT format validation (starts with "eyJ")
    if (!appleIDToken.startsWith('eyJ')) {
        return sendError(res, 400, 'Invalid Apple ID token format', ErrorCodes.VALIDATION_ERROR, 'INVALID_TOKEN_FORMAT');
    }
    
    next();
};

/**
 * Validate message in request body
 */
const validateMessage = (req, res, next) => {
    const { message } = req.body;
    
    if (!message || typeof message !== 'string' || message.trim().length === 0) {
        return sendError(res, 400, 'Message content is required', ErrorCodes.VALIDATION_ERROR, 'EMPTY_MESSAGE');
    }
    
    if (message.trim().length > 5000) {
        return sendError(res, 400, 'Message exceeds maximum length of 5000 characters', ErrorCodes.VALIDATION_ERROR, 'MESSAGE_TOO_LONG');
    }
    
    next();
};

/**
 * Validate conversation array in request body
 */
const validateConversation = (req, res, next) => {
    const { conversation } = req.body;
    
    // Conversation is optional, but if provided, it must be an array
    if (conversation !== undefined && !Array.isArray(conversation)) {
        return sendError(res, 400, 'Conversation must be an array', ErrorCodes.VALIDATION_ERROR, 'INVALID_CONVERSATION_FORMAT');
    }
    
    // Validate conversation items if array is provided
    if (Array.isArray(conversation)) {
        for (let i = 0; i < conversation.length; i++) {
            const msg = conversation[i];
            if (!msg || typeof msg !== 'object') {
                return sendError(res, 400, `Invalid conversation message at index ${i}`, ErrorCodes.VALIDATION_ERROR, 'INVALID_MESSAGE_FORMAT');
            }
            if (typeof msg.role !== 'string' || (msg.role !== 'user' && msg.role !== 'assistant')) {
                return sendError(res, 400, `Invalid message role at index ${i}. Must be 'user' or 'assistant'`, ErrorCodes.VALIDATION_ERROR, 'INVALID_MESSAGE_ROLE');
            }
            if (typeof msg.content !== 'string') {
                return sendError(res, 400, `Invalid message content at index ${i}`, ErrorCodes.VALIDATION_ERROR, 'INVALID_MESSAGE_CONTENT');
            }
            if (msg.content.trim().length === 0) {
                return sendError(res, 400, `Empty message content at index ${i}`, ErrorCodes.VALIDATION_ERROR, 'EMPTY_MESSAGE_CONTENT');
            }
            if (msg.content.length > 5000) {
                return sendError(res, 400, `Message content at index ${i} exceeds maximum length`, ErrorCodes.VALIDATION_ERROR, 'MESSAGE_TOO_LONG');
            }
        }
    }
    
    next();
};

/**
 * Validate pairing code in request body
 */
const validatePairingCode = (req, res, next) => {
    const { pairingCode } = req.body;
    
    if (!pairingCode || typeof pairingCode !== 'string' || pairingCode.trim().length === 0) {
        return sendError(res, 400, 'Pairing code is required', ErrorCodes.VALIDATION_ERROR, 'MISSING_PAIRING_CODE');
    }
    
    // Pairing codes should be 6 digits
    if (!/^\d{6}$/.test(pairingCode.trim())) {
        return sendError(res, 400, 'Invalid pairing code format. Must be 6 digits', ErrorCodes.VALIDATION_ERROR, 'INVALID_PAIRING_CODE_FORMAT');
    }
    
    next();
};

module.exports = {
    validateAppleIDToken,
    validateMessage,
    validateConversation,
    validatePairingCode
};

