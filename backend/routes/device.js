const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { getDbClient } = require('../database/client');

const router = express.Router();

// Middleware to verify user token
const verifyUserToken = (req, res, next) => {
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
        
        if (decoded.type !== 'user') {
            return res.status(401).json({
                message: 'Invalid token type',
                code: 'INVALID_TOKEN_TYPE'
            });
        }

        req.userId = decoded.userId;
        next();
    } catch (error) {
        res.status(401).json({
            message: 'Invalid token',
            code: 'INVALID_TOKEN'
        });
    }
};

// POST /device/pair - Pair a device with user account
router.post('/pair', verifyUserToken, async (req, res) => {
    try {
        const { pairingCode } = req.body;
        const { deviceType = 'iphone' } = req.body; // Default to iPhone
        
        if (!pairingCode) {
            return res.status(400).json({
                message: 'Pairing code is required',
                code: 'MISSING_PAIRING_CODE'
            });
        }

        const db = getDbClient();
        let pairingRecord;

        if (db.type === 'prisma') {
            const prisma = db.client;
            pairingRecord = await prisma.pairingCode.findFirst({
                where: {
                    code: pairingCode,
                    userId: req.userId,
                    expiresAt: { gt: new Date() },
                    used: false
                }
            });
        } else {
            // SQLite fallback
            const sqliteDb = db.client;
            pairingRecord = await new Promise((resolve, reject) => {
                sqliteDb.get(
                    `SELECT * FROM pairing_codes 
                     WHERE code = ? AND user_id = ? AND expires_at > datetime('now') AND used = FALSE`,
                    [pairingCode, req.userId],
                    (err, row) => {
                        if (err) reject(err);
                        else resolve(row);
                    }
                );
            });
        }

        if (!pairingRecord) {
            return res.status(400).json({
                message: 'Invalid or expired pairing code',
                code: 'INVALID_PAIRING_CODE'
            });
        }

        // Mark pairing code as used
        if (db.type === 'prisma') {
            await db.client.pairingCode.update({
                where: { id: pairingRecord.id },
                data: { used: true }
            });
        } else {
            const sqliteDb = db.client;
            await new Promise((resolve, reject) => {
                sqliteDb.run(
                    'UPDATE pairing_codes SET used = TRUE WHERE id = ?',
                    [pairingRecord.id],
                    (err) => {
                        if (err) reject(err);
                        else resolve();
                    }
                );
            });
        }

        // Create device record
        const deviceId = uuidv4();
        const deviceToken = jwt.sign(
            { 
                deviceId: deviceId,
                userId: req.userId,
                type: 'device'
            },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        if (db.type === 'prisma') {
            await db.client.device.create({
                data: {
                    id: deviceId,
                    userId: req.userId,
                    deviceType,
                    deviceToken
                }
            });
        } else {
            const sqliteDb = db.client;
            await new Promise((resolve, reject) => {
                sqliteDb.run(
                    'INSERT INTO devices (id, user_id, device_type, device_token) VALUES (?, ?, ?, ?)',
                    [deviceId, req.userId, deviceType, deviceToken],
                    (err) => {
                        if (err) reject(err);
                        else resolve();
                    }
                );
            });
        }

        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

        res.json({
            deviceToken,
            deviceId,
            expiresAt
        });

    } catch (error) {
        console.error('Device pairing error:', error);
        res.status(500).json({
            message: 'Device pairing failed',
            code: 'PAIRING_ERROR'
        });
    }
});

// POST /device/auto-pair - Automatically pair device after authentication (no code needed)
router.post('/auto-pair', verifyUserToken, async (req, res) => {
    try {
        const { deviceType = 'iphone' } = req.body;
        const db = getDbClient();
        
        // Check if device already exists for this user
        let existingDevice;
        if (db.type === 'prisma') {
            const prisma = db.client;
            existingDevice = await prisma.device.findFirst({
                where: {
                    userId: req.userId,
                    deviceType
                }
            });
        } else {
            const sqliteDb = db.client;
            existingDevice = await new Promise((resolve, reject) => {
                sqliteDb.get(
                    'SELECT * FROM devices WHERE user_id = ? AND device_type = ?',
                    [req.userId, deviceType],
                    (err, row) => {
                        if (err) reject(err);
                        else resolve(row);
                    }
                );
            });
        }
        
        // If device exists, return existing token
        if (existingDevice) {
            const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
            return res.json({
                deviceToken: existingDevice.deviceToken || existingDevice.device_token,
                deviceId: existingDevice.id,
                expiresAt
            });
        }
        
        // Create new device
        const deviceId = uuidv4();
        const deviceToken = jwt.sign(
            { 
                deviceId: deviceId,
                userId: req.userId,
                type: 'device'
            },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );
        
        if (db.type === 'prisma') {
            await db.client.device.create({
                data: {
                    id: deviceId,
                    userId: req.userId,
                    deviceType,
                    deviceToken
                }
            });
        } else {
            const sqliteDb = db.client;
            await new Promise((resolve, reject) => {
                sqliteDb.run(
                    'INSERT INTO devices (id, user_id, device_type, device_token) VALUES (?, ?, ?, ?)',
                    [deviceId, req.userId, deviceType, deviceToken],
                    (err) => {
                        if (err) reject(err);
                        else resolve();
                    }
                );
            });
        }
        
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
        
        res.json({
            deviceToken,
            deviceId,
            expiresAt
        });
        
    } catch (error) {
        console.error('Auto-pair error:', error);
        res.status(500).json({
            message: 'Auto-pairing failed',
            code: 'AUTO_PAIR_ERROR'
        });
    }
});

// POST /device/generate-pairing-code - Generate a new pairing code
router.post('/generate-pairing-code', verifyUserToken, async (req, res) => {
    try {
        const db = getDbClient();
        
        // Generate 6-digit pairing code
        const pairingCode = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes from now
        
        const codeId = uuidv4();
        
        if (db.type === 'prisma') {
            await db.client.pairingCode.create({
                data: {
                    id: codeId,
                    userId: req.userId,
                    code: pairingCode,
                    expiresAt
                }
            });
        } else {
            const sqliteDb = db.client;
            await new Promise((resolve, reject) => {
                sqliteDb.run(
                    'INSERT INTO pairing_codes (id, user_id, code, expires_at) VALUES (?, ?, ?, ?)',
                    [codeId, req.userId, pairingCode, expiresAt.toISOString()],
                    (err) => {
                        if (err) reject(err);
                        else resolve();
                    }
                );
            });
        }

        res.json({
            pairingCode,
            expiresAt: expiresAt.toISOString()
        });

    } catch (error) {
        console.error('Pairing code generation error:', error);
        res.status(500).json({
            message: 'Failed to generate pairing code',
            code: 'PAIRING_CODE_ERROR'
        });
    }
});

// GET /device/devices - Get user's devices
router.get('/devices', verifyUserToken, async (req, res) => {
    try {
        const db = getDbClient();
        
        let devices;

        if (db.type === 'prisma') {
            devices = await db.client.device.findMany({
                where: { userId: req.userId },
                orderBy: { createdAt: 'desc' },
                select: { id: true, deviceType: true, createdAt: true }
            });
            devices = devices.map(d => ({
                id: d.id,
                device_type: d.deviceType,
                created_at: d.createdAt.toISOString()
            }));
        } else {
            const sqliteDb = db.client;
            devices = await new Promise((resolve, reject) => {
                sqliteDb.all(
                    'SELECT id, device_type, created_at FROM devices WHERE user_id = ?',
                    [req.userId],
                    (err, rows) => {
                        if (err) reject(err);
                        else resolve(rows);
                    }
                );
            });
        }

        res.json(devices);

    } catch (error) {
        console.error('Get devices error:', error);
        res.status(500).json({
            message: 'Failed to get devices',
            code: 'GET_DEVICES_ERROR'
        });
    }
});

module.exports = router;
