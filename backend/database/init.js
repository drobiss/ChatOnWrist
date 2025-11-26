// Only load SQLite if we're not using PostgreSQL
let sqlite3 = null;
let DB_PATH = null;

function loadSQLite() {
    const dbUrl = process.env.DATABASE_URL || '';
    // Only use SQLite if DATABASE_URL is not PostgreSQL
    if (dbUrl.includes('postgresql://') || dbUrl.includes('postgres://')) {
        return false; // Using PostgreSQL
    }
    
    if (!sqlite3) {
        try {
            // Try to load sqlite3 - it might not be available in production
            sqlite3 = require('sqlite3').verbose();
            DB_PATH = process.env.DATABASE_PATH || './database.sqlite';
        } catch (error) {
            // If sqlite3 is not available and no PostgreSQL URL, this is an error
            if (!dbUrl) {
                console.error('❌ ERROR: sqlite3 not available and no DATABASE_URL set. Please add PostgreSQL to Railway or ensure sqlite3 is installed.');
                throw new Error('Database not configured: sqlite3 unavailable and no DATABASE_URL');
            }
            console.warn('⚠️ sqlite3 module not available. Using PostgreSQL only.');
            return false;
        }
    }
    return sqlite3 !== null;
}

// Singleton database instance
let dbInstance = null;
let isInitialized = false;

function initializeDatabase() {
    return new Promise((resolve, reject) => {
        // Check if we should use SQLite
        if (!loadSQLite()) {
            // Using PostgreSQL, skip SQLite initialization
            console.log('📊 Skipping SQLite initialization (using PostgreSQL)');
            resolve();
            return;
        }
        
        // If already initialized, resolve immediately
        if (isInitialized && dbInstance) {
            resolve();
            return;
        }

        dbInstance = new sqlite3.Database(DB_PATH, (err) => {
            if (err) {
                console.error('Error opening database:', err);
                dbInstance = null;
                reject(err);
                return;
            }
            console.log('Connected to SQLite database');
            
            // Configure connection settings
            dbInstance.configure('busyTimeout', 5000); // Wait up to 5 seconds for locks
            
            // Enable foreign keys
            dbInstance.run('PRAGMA foreign_keys = ON', (err) => {
                if (err) {
                    console.warn('Warning: Could not enable foreign keys:', err);
                }
            });
        });

        // Handle database errors
        dbInstance.on('error', (err) => {
            console.error('Database error:', err);
            // Don't close on error - let the application handle it
        });

        // Create tables
        const createTables = `
            -- Users table
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                apple_user_id TEXT UNIQUE NOT NULL,
                email TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            -- Devices table
            CREATE TABLE IF NOT EXISTS devices (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                device_type TEXT NOT NULL CHECK (device_type IN ('iphone', 'watch')),
                device_token TEXT UNIQUE NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            );

            -- Conversations table
            CREATE TABLE IF NOT EXISTS conversations (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                title TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (device_id) REFERENCES devices (id) ON DELETE CASCADE
            );

            -- Messages table
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                conversation_id TEXT NOT NULL,
                content TEXT NOT NULL,
                is_from_user BOOLEAN NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE
            );

            -- Pairing codes table (temporary)
            CREATE TABLE IF NOT EXISTS pairing_codes (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                code TEXT NOT NULL,
                expires_at DATETIME NOT NULL,
                used BOOLEAN DEFAULT FALSE,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            );

            -- Create indexes for better performance
            CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);
            CREATE INDEX IF NOT EXISTS idx_conversations_device_id ON conversations(device_id);
            CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
            CREATE INDEX IF NOT EXISTS idx_pairing_codes_code ON pairing_codes(code);
            CREATE INDEX IF NOT EXISTS idx_pairing_codes_expires ON pairing_codes(expires_at);
        `;

        dbInstance.exec(createTables, (err) => {
            if (err) {
                console.error('Error creating tables:', err);
                dbInstance.close();
                dbInstance = null;
                reject(err);
                return;
            }
            console.log('Database tables created successfully');
            isInitialized = true;
            resolve();
        });
    });
}

function getDatabase() {
    // Check if we should use SQLite
    const dbUrl = process.env.DATABASE_URL || '';
    if (dbUrl.includes('postgresql://') || dbUrl.includes('postgres://')) {
        throw new Error('PostgreSQL is configured. Routes need to be migrated to use Prisma instead of getDatabase().');
    }
    
    if (!loadSQLite()) {
        throw new Error('SQLite not available. Please configure DATABASE_URL for PostgreSQL or ensure sqlite3 is installed.');
    }
    
    if (!dbInstance) {
        throw new Error('Database not initialized. Call initializeDatabase() first.');
    }
    return dbInstance;
}

// Graceful shutdown function
function closeDatabase() {
    return new Promise((resolve, reject) => {
        if (!dbInstance) {
            resolve();
            return;
        }
        
        dbInstance.close((err) => {
            if (err) {
                console.error('Error closing database:', err);
                reject(err);
            } else {
                console.log('Database connection closed');
                dbInstance = null;
                isInitialized = false;
                resolve();
            }
        });
    });
}

module.exports = {
    initializeDatabase,
    getDatabase,
    closeDatabase
};
