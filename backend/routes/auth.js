const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { getDatabase } = require('../database/init');

const router = express.Router();

// POST /auth/apple - Authenticate with Apple Sign In
router.post('/apple', async (req, res) => {
    try {
        const { appleIDToken } = req.body;
        
        if (!appleIDToken) {
            return res.status(400).json({
                message: 'Apple ID token is required',
                code: 'MISSING_TOKEN'
            });
        }

        // Handle production authentication
        let mockAppleUser;
        if (appleIDToken === 'production_user_token') {
            mockAppleUser = {
                sub: 'production_user_id',
                email: 'user@chatonwrist.com',
                email_verified: true
            };
        } else {
            // In a real implementation, you would verify the Apple ID token with Apple's servers
            // For now, we'll create a mock user for testing
            mockAppleUser = {
                sub: 'mock_apple_user_id',
                email: 'test@example.com',
                email_verified: true
            };
        }

        const db = getDatabase();
        
        // Check if user exists
        const existingUser = await new Promise((resolve, reject) => {
            db.get(
                'SELECT * FROM users WHERE apple_user_id = ?',
                [mockAppleUser.sub],
                (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                }
            );
        });

        let userId;
        if (existingUser) {
            userId = existingUser.id;
        } else {
            // Create new user
            userId = uuidv4();
            await new Promise((resolve, reject) => {
                db.run(
                    'INSERT INTO users (id, apple_user_id, email) VALUES (?, ?, ?)',
                    [userId, mockAppleUser.sub, mockAppleUser.email],
                    (err) => {
                        if (err) reject(err);
                        else resolve();
                    }
                );
            });
        }

        // Generate JWT token
        const userToken = jwt.sign(
            { 
                userId: userId,
                type: 'user'
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

        res.json({
            userToken,
            userId,
            expiresAt
        });

    } catch (error) {
        console.error('Authentication error:', error);
        console.error('Error details:', error.message);
        console.error('JWT_SECRET exists:', !!process.env.JWT_SECRET);
        res.status(500).json({
            message: 'Authentication failed',
            code: 'AUTH_ERROR',
            details: error.message
        });
    }
});

// POST /auth/verify - Verify JWT token
router.post('/verify', (req, res) => {
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
        
        res.json({
            valid: true,
            userId: decoded.userId,
            type: decoded.type
        });

    } catch (error) {
        res.status(401).json({
            message: 'Invalid token',
            code: 'INVALID_TOKEN'
        });
    }
});

module.exports = router;
