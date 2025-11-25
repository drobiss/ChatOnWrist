const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const deviceRoutes = require('./routes/device');
const chatRoutes = require('./routes/chat');
const { initializeDatabase, closeDatabase } = require('./database/init');

const app = express();
const PORT = process.env.PORT || 3000;

// Validate required environment variables
const requiredEnvVars = ['JWT_SECRET', 'OPENAI_API_KEY'];
const missing = requiredEnvVars.filter(v => !process.env[v]);

if (missing.length > 0) {
    console.error('❌ Missing required environment variables:', missing.join(', '));
    console.error('Please set these variables before starting the server.');
    process.exit(1);
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

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Admin endpoint to view users (PROTECTED - requires admin key)
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

// Initialize database and start server
async function startServer() {
    try {
        console.log('Starting ChatOnWrist Backend Server...');
        console.log('Environment:', process.env.NODE_ENV || 'development');
        console.log('Port:', PORT);
        
        await initializeDatabase();
        console.log('Database initialized successfully');
        
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
        
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

startServer();

// Graceful shutdown
async function gracefulShutdown(signal) {
    console.log(`${signal} received, shutting down gracefully...`);
    try {
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
