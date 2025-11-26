const { PrismaClient } = require('@prisma/client');

let prisma = null;

function getPrismaClient() {
    if (!prisma) {
        prisma = new PrismaClient({
            log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
        });
    }
    return prisma;
}

async function initializePrisma() {
    const client = getPrismaClient();
    // Test connection
    await client.$connect();
    console.log('✅ Prisma Client connected to database');
    
    // Push schema to database (creates tables if they don't exist)
    try {
        const { execSync } = require('child_process');
        console.log('📊 Pushing Prisma schema to database...');
        execSync('npx prisma db push --skip-generate', { 
            stdio: 'inherit',
            cwd: require('path').join(__dirname, '..')
        });
        console.log('✅ Database schema synced');
    } catch (error) {
        console.warn('⚠️ Could not push schema (this is OK if tables already exist):', error.message);
    }
    
    return client;
}

async function closePrisma() {
    if (prisma) {
        await prisma.$disconnect();
        prisma = null;
        console.log('✅ Prisma Client disconnected');
    }
}

module.exports = {
    getPrismaClient,
    initializePrisma,
    closePrisma
};

