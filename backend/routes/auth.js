const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { getDbClient } = require('../database/client');
const { validateAppleIDToken } = require('../middleware/validation');
const { sendError, ErrorCodes } = require('../utils/errors');
const { verifyAppleIDToken } = require('../utils/appleAuth');

const router = express.Router();

// POST /auth/apple - Authenticate with Apple Sign In
router.post('/apple', validateAppleIDToken, async (req, res) => {
    try {
        const { appleIDToken } = req.body;

        // Verify Apple ID token
        const appleUser = verifyAppleIDToken(appleIDToken);
        
        if (!appleUser) {
            return sendError(res, 401, 'Invalid Apple ID token', ErrorCodes.INVALID_TOKEN);
        }
        
        console.log('✅ Verified Apple ID token for user:', appleUser.userId);

        const db = getDbClient();
        let userId;
        
        if (db.type === 'prisma') {
            // Use Prisma for PostgreSQL
            const prisma = db.client;
            
            // Check if user exists
            let existingUser = await prisma.user.findUnique({
                where: { appleUserId: appleUser.userId }
            });
            
            if (existingUser) {
                userId = existingUser.id;
                // Update email if it changed
                if (appleUser.email && appleUser.email !== existingUser.email) {
                    await prisma.user.update({
                        where: { id: userId },
                        data: { email: appleUser.email }
                    });
                }
            } else {
                // Create new user
                userId = uuidv4();
                await prisma.user.create({
                    data: {
                        id: userId,
                        appleUserId: appleUser.userId,
                        email: appleUser.email || null
                    }
                });
            }
        } else {
            // Use SQLite
            const sqliteDb = db.client;
            
            // Check if user exists
            const existingUser = await new Promise((resolve, reject) => {
                sqliteDb.get(
                    'SELECT * FROM users WHERE apple_user_id = ?',
                    [appleUser.userId],
                    (err, row) => {
                        if (err) reject(err);
                        else resolve(row);
                    }
                );
            });

            if (existingUser) {
                userId = existingUser.id;
                // Update email if it changed (Apple allows email changes)
                if (appleUser.email && appleUser.email !== existingUser.email) {
                    await new Promise((resolve, reject) => {
                        sqliteDb.run(
                            'UPDATE users SET email = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
                            [appleUser.email, userId],
                            (err) => {
                                if (err) reject(err);
                                else resolve();
                            }
                        );
                    });
                }
            } else {
                // Create new user
                userId = uuidv4();
                await new Promise((resolve, reject) => {
                    sqliteDb.run(
                        'INSERT INTO users (id, apple_user_id, email) VALUES (?, ?, ?)',
                        [userId, appleUser.userId, appleUser.email || null],
                        (err) => {
                            if (err) reject(err);
                            else resolve();
                        }
                    );
                });
            }
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
        sendError(res, 500, 'Authentication failed', ErrorCodes.AUTH_ERROR, error.message);
    }
});

// POST /auth/verify - Verify JWT token
router.post('/verify', (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return sendError(res, 401, 'Authorization token required', ErrorCodes.MISSING_TOKEN);
        }

        const token = authHeader.substring(7);
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        res.json({
            valid: true,
            userId: decoded.userId,
            type: decoded.type
        });

    } catch (error) {
        sendError(res, 401, 'Invalid token', ErrorCodes.INVALID_TOKEN);
    }
});

module.exports = router;
