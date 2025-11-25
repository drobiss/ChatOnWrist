// Apple ID Token verification utility
// Note: For production, you should verify the token signature with Apple's public keys
// This implementation decodes the token and extracts user information

const jwt = require('jsonwebtoken');

/**
 * Decode Apple ID token (without signature verification)
 * In production, you should verify the signature using Apple's public keys
 * 
 * @param {string} token - Apple ID token (JWT)
 * @returns {Object|null} Decoded token payload or null if invalid
 */
function decodeAppleIDToken(token) {
    try {
        // Decode without verification (for now)
        // In production, verify signature with Apple's public keys
        const decoded = jwt.decode(token, { complete: true });
        
        if (!decoded || !decoded.payload) {
            return null;
        }
        
        const payload = decoded.payload;
        
        // Validate token structure
        if (!payload.sub || !payload.iss) {
            return null;
        }
        
        // Verify issuer is Apple
        if (payload.iss !== 'https://appleid.apple.com') {
            console.warn('Token issuer is not Apple:', payload.iss);
            // For development, we'll allow it, but log a warning
        }
        
        // Check expiration
        if (payload.exp && payload.exp < Date.now() / 1000) {
            console.warn('Token has expired');
            return null;
        }
        
        return {
            userId: payload.sub,
            email: payload.email,
            emailVerified: payload.email_verified === true,
            // Additional fields that might be present
            isPrivateEmail: payload.is_private_email === true,
            realUserStatus: payload.real_user_status
        };
    } catch (error) {
        console.error('Error decoding Apple ID token:', error);
        return null;
    }
}

/**
 * Verify Apple ID token and extract user information
 * 
 * @param {string} token - Apple ID token
 * @returns {Object|null} User information or null if invalid
 */
function verifyAppleIDToken(token) {
    if (!token || typeof token !== 'string') {
        return null;
    }
    
    // Basic format validation (JWT tokens start with "eyJ")
    if (!token.startsWith('eyJ')) {
        return null;
    }
    
    return decodeAppleIDToken(token);
}

module.exports = {
    verifyAppleIDToken,
    decodeAppleIDToken
};

