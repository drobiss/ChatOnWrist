#!/bin/bash

# Quick script to download Railway database and view it

cd "$(dirname "$0")"

echo "🔍 Checking Railway connection..."
if ! railway whoami &>/dev/null; then
    echo "❌ Not logged into Railway. Please run: railway login"
    exit 1
fi

echo "📥 Downloading database from Railway..."
railway run cat database.sqlite > railway-db.sqlite 2>&1

if [ -f "railway-db.sqlite" ] && [ -s "railway-db.sqlite" ]; then
    echo "✅ Database downloaded!"
    echo ""
    echo "📊 Database stats:"
    sqlite3 railway-db.sqlite "SELECT 'Users: ' || COUNT(*) FROM users; SELECT 'Devices: ' || COUNT(*) FROM devices; SELECT 'Conversations: ' || COUNT(*) FROM conversations; SELECT 'Messages: ' || COUNT(*) FROM messages;"
    echo ""
    echo "🚀 Opening Prisma Studio..."
    echo "📝 Update .env to use: DATABASE_URL=\"file:./railway-db.sqlite\""
    
    # Temporarily update .env
    OLD_DB=$(grep DATABASE_URL .env | head -1)
    echo 'DATABASE_URL="file:./railway-db.sqlite"' > .env.tmp
    grep -v DATABASE_URL .env >> .env.tmp 2>/dev/null || true
    mv .env.tmp .env
    
    npx prisma generate
    echo ""
    echo "✅ Prisma Studio starting... Open http://localhost:5555"
    npx prisma studio --port 5555
else
    echo "❌ Could not download database"
    echo ""
    echo "Try manually:"
    echo "  railway run sqlite3 database.sqlite 'SELECT * FROM users;'"
fi

