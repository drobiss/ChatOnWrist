const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const deviceRoutes = require('./routes/device');
const chatRoutes = require('./routes/chat');
const { initializeDatabase } = require('./database/init');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
    origin: ['http://localhost:3000', 'https://api.chatonwrist.com'],
    credentials: true
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

// Admin endpoint to view users (for development)
app.get('/admin/users', async (req, res) => {
    try {
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
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
});
