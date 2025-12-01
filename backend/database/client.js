const { getDatabase } = require('./init');
const { getPrismaClient } = require('./prisma');

function isPostgresConfigured() {
    const dbUrl = process.env.DATABASE_URL || '';
    return dbUrl.includes('postgresql://') || dbUrl.includes('postgres://');
}

/**
 * Return the active database client.
 * - If DATABASE_URL points to Postgres, Prisma is returned.
 * - Otherwise SQLite is used (and must be initialized elsewhere).
 */
function getDbClient() {
    if (isPostgresConfigured()) {
        return { type: 'prisma', client: getPrismaClient() };
    }

    // Fallback to SQLite for local/dev use without Postgres
    return { type: 'sqlite', client: getDatabase() };
}

module.exports = {
    getDbClient,
    isPostgresConfigured
};
