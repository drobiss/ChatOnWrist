const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const deviceRoutes = require('./routes/device');
const chatRoutes = require('./routes/chat');
const { initializeDatabase, closeDatabase } = require('./database/init');
const { initializePrisma, closePrisma } = require('./database/prisma');

const app = express();
const PORT = process.env.PORT || 3000;

// Check required environment variables (but don't exit - let healthcheck work)
const requiredEnvVars = ['JWT_SECRET', 'OPENAI_API_KEY'];
const missing = requiredEnvVars.filter(v => !process.env[v]);

if (missing.length > 0) {
    console.error('⚠️ Missing required environment variables:', missing.join(', '));
    console.error('⚠️ Some features may not work until these are set.');
    // Don't exit - let server start for healthcheck
}

// Security middleware
app.use(helmet());

// CORS configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS 
    ? process.env.ALLOWED_ORIGINS.split(',').map(origin => origin.trim())
    : [
        'http://localhost:3000',
        'https://chatonwrist-production-79ac.up.railway.app'
    ];

app.use(cors({
    origin: (origin, callback) => {
        // Allow requests with no origin (like mobile apps or curl requests)
        if (!origin) {
            return callback(null, true);
        }
        
        if (allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            console.warn(`CORS blocked origin: ${origin}`);
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 3600000, // 1 hour
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check endpoint - must be available immediately for Railway healthcheck
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        database: 'initializing'
    });
});

// Admin endpoint to view database (PROTECTED - requires admin key)
app.get('/admin/dashboard', async (req, res) => {
    try {
        // Check for admin key in query parameter
        const adminKey = req.query.key;
        const expectedKey = process.env.ADMIN_KEY;
        
        if (!expectedKey) {
            return res.status(503).json({ 
                error: 'Admin endpoint not configured',
                message: 'ADMIN_KEY environment variable is not set'
            });
        }
        
        if (!adminKey || adminKey !== expectedKey) {
            return res.status(401).json({ 
                error: 'Unauthorized - admin key required',
                hint: 'Add ?key=your_admin_key to the URL'
            });
        }
        
        const dbUrl = process.env.DATABASE_URL || '';
        const usePrisma = dbUrl.includes('postgresql://') || dbUrl.includes('postgres://');
        
        let users, devices, conversations, messages, recentMessages;
        
        if (usePrisma) {
            // Use Prisma for PostgreSQL
            const { getPrismaClient } = require('./database/prisma');
            const prisma = getPrismaClient();
            
            [users, devices, conversations, messages, recentMessages] = await Promise.all([
                prisma.user.findMany({
                    orderBy: { createdAt: 'desc' },
                    select: {
                        id: true,
                        appleUserId: true,
                        email: true,
                        createdAt: true,
                        updatedAt: true
                    }
                }),
                prisma.device.findMany({
                    orderBy: { createdAt: 'desc' },
                    include: {
                        user: {
                            select: { email: true }
                        }
                    }
                }),
                prisma.conversation.findMany({
                    orderBy: { updatedAt: 'desc' },
                    include: {
                        device: {
                            include: {
                                user: {
                                    select: { email: true }
                                }
                            },
                            select: { deviceType: true }
                        },
                        _count: {
                            select: { messages: true }
                        }
                    }
                }),
                prisma.message.count(),
                prisma.message.findMany({
                    take: 20,
                    orderBy: { createdAt: 'desc' },
                    include: {
                        conversation: {
                            include: {
                                device: {
                                    include: {
                                        user: {
                                            select: { email: true }
                                        }
                                    }
                                },
                                select: { title: true }
                            }
                        }
                    }
                })
            ]);
            
            // Transform Prisma results to match expected format
            devices = devices.map(d => ({
                id: d.id,
                device_type: d.deviceType,
                device_token: d.deviceToken,
                created_at: d.createdAt,
                user_email: d.user?.email || null
            }));
            
            conversations = conversations.map(c => ({
                id: c.id,
                title: c.title,
                created_at: c.createdAt,
                updated_at: c.updatedAt,
                device_type: c.device?.deviceType || null,
                user_email: c.device?.user?.email || null,
                message_count: c._count.messages
            }));
            
            recentMessages = recentMessages.map(m => ({
                id: m.id,
                content: m.content,
                is_from_user: m.isFromUser,
                created_at: m.createdAt,
                conversation_title: m.conversation?.title || null,
                user_email: m.conversation?.device?.user?.email || null
            }));
            
        } else {
            // Use SQLite (backward compatible)
            const { getDatabase } = require('./database/init');
            const db = getDatabase();
            
            [users, devices, conversations, messages, recentMessages] = await Promise.all([
                new Promise((resolve, reject) => {
                    db.all('SELECT id, apple_user_id, email, created_at, updated_at FROM users ORDER BY created_at DESC', (err, rows) => {
                        if (err) reject(err);
                        else resolve(rows);
                    });
                }),
                new Promise((resolve, reject) => {
                    db.all(`SELECT d.id, d.device_type, d.device_token, d.created_at, u.email as user_email 
                            FROM devices d 
                            LEFT JOIN users u ON d.user_id = u.id 
                            ORDER BY d.created_at DESC`, (err, rows) => {
                        if (err) reject(err);
                        else resolve(rows);
                    });
                }),
                new Promise((resolve, reject) => {
                    db.all(`SELECT c.id, c.title, c.created_at, c.updated_at, 
                                   d.device_type, u.email as user_email,
                                   COUNT(m.id) as message_count
                            FROM conversations c 
                            LEFT JOIN devices d ON c.device_id = d.id 
                            LEFT JOIN users u ON d.user_id = u.id
                            LEFT JOIN messages m ON c.id = m.conversation_id
                            GROUP BY c.id
                            ORDER BY c.updated_at DESC`, (err, rows) => {
                        if (err) reject(err);
                        else resolve(rows);
                    });
                }),
                new Promise((resolve, reject) => {
                    db.get('SELECT COUNT(*) as count FROM messages', (err, row) => {
                        if (err) reject(err);
                        else resolve(row?.count || 0);
                    });
                }),
                new Promise((resolve, reject) => {
                    db.all(`SELECT m.id, m.content, m.is_from_user, m.created_at,
                                   c.title as conversation_title, u.email as user_email
                            FROM messages m
                            LEFT JOIN conversations c ON m.conversation_id = c.id
                            LEFT JOIN devices d ON c.device_id = d.id
                            LEFT JOIN users u ON d.user_id = u.id
                            ORDER BY m.created_at DESC
                            LIMIT 20`, (err, rows) => {
                        if (err) reject(err);
                        else resolve(rows);
                    });
                })
            ]);
        }
        
        res.json({
            stats: {
                users: users.length,
                devices: devices.length,
                conversations: conversations.length,
                messages: messages
            },
            users: users,
            devices: devices,
            conversations: conversations,
            recentMessages: recentMessages
        });
    } catch (error) {
        console.error('Error fetching dashboard data:', error);
        res.status(500).json({ error: 'Failed to fetch dashboard data', details: error.message });
    }
});

// Admin endpoint to view users (PROTECTED - requires admin key) - kept for backward compatibility
app.get('/admin/users', async (req, res) => {
    try {
        // Check for admin key in query parameter
        const adminKey = req.query.key;
        const expectedKey = process.env.ADMIN_KEY;
        
        if (!expectedKey) {
            return res.status(503).json({ 
                error: 'Admin endpoint not configured',
                message: 'ADMIN_KEY environment variable is not set'
            });
        }
        
        if (!adminKey || adminKey !== expectedKey) {
            return res.status(401).json({ 
                error: 'Unauthorized - admin key required',
                hint: 'Add ?key=your_admin_key to the URL'
            });
        }
        
        const { getDatabase } = require('./database/init');
        const db = getDatabase();
        
        const users = await new Promise((resolve, reject) => {
            db.all('SELECT * FROM users ORDER BY created_at DESC', (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
        
        res.json({
            count: users.length,
            users: users
        });
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// Test chat endpoint (no auth required for testing)
app.post('/test-chat', async (req, res) => {
    try {
        const { message } = req.body;
        
        if (!message) {
            return res.status(400).json({ error: 'Message is required' });
        }
        
        // Call OpenAI API
        const axios = require('axios');
        const openaiResponse = await axios.post('https://api.openai.com/v1/chat/completions', {
            model: 'gpt-4o',
            messages: [{ role: 'user', content: message }],
            max_tokens: 150,
            temperature: 0.7
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });
        
        const aiResponse = openaiResponse.data.choices[0].message.content;
        
        res.json({
            response: aiResponse,
            conversationId: 'test-conversation',
            messageId: 'test-message'
        });
        
    } catch (error) {
        console.error('Test chat error:', error);
        res.status(500).json({ error: 'Failed to process message' });
    }
});

// API routes
app.use('/auth', authRoutes);
app.use('/device', deviceRoutes);
app.use('/chat', chatRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        message: 'Internal server error',
        code: 'INTERNAL_ERROR'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        message: 'Endpoint not found',
        code: 'NOT_FOUND'
    });
});

// Start server first (before database init) so healthcheck works
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 ChatOnWrist Backend Server running on port ${PORT}`);
    console.log(`📱 Health check: http://0.0.0.0:${PORT}/health`);
    console.log(`🔗 API Base URL: http://0.0.0.0:${PORT}`);
});

// Handle server errors
server.on('error', (err) => {
    console.error('Server error:', err);
    if (err.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use`);
    }
    process.exit(1);
});

// Initialize database after server starts
async function initializeServer() {
    try {
        console.log('Starting ChatOnWrist Backend Server...');
        console.log('Environment:', process.env.NODE_ENV || 'development');
        console.log('Port:', PORT);
        
        // Check DATABASE_URL
        const dbUrl = process.env.DATABASE_URL || '';
        console.log('📊 DATABASE_URL:', dbUrl ? `${dbUrl.substring(0, 20)}...` : 'NOT SET');
        
        // Try Prisma first (PostgreSQL), fallback to SQLite
        if (dbUrl.includes('postgresql://') || dbUrl.includes('postgres://')) {
            console.log('📊 Using PostgreSQL with Prisma...');
            await initializePrisma();
            console.log('✅ Prisma initialized successfully');
            console.log('⚠️  NOTE: Routes still use SQLite queries. They need to be migrated to Prisma.');
        } else {
            console.log('📊 Using SQLite...');
            await initializeDatabase();
            console.log('✅ SQLite initialized successfully');
        }
        
        // Update health endpoint to show database is ready
        app.get('/health', (req, res) => {
            res.status(200).json({
                status: 'OK',
                timestamp: new Date().toISOString(),
                uptime: process.uptime(),
                database: 'ready'
            });
        });
        
    } catch (error) {
        console.error('Failed to initialize database:', error);
        // Don't exit - let server continue running for healthcheck
        // Database will be initialized on next request if needed
    }
}

initializeServer();

// Graceful shutdown
async function gracefulShutdown(signal) {
    console.log(`${signal} received, shutting down gracefully...`);
    try {
        await closePrisma();
        await closeDatabase();
        console.log('Database closed successfully');
        process.exit(0);
    } catch (error) {
        console.error('Error during shutdown:', error);
        process.exit(1);
    }
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
