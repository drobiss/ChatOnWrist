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

