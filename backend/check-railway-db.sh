#!/bin/bash

# Script to check Railway database via CLI

cd "$(dirname "$0")"

echo "🔍 Checking Railway Database..."
echo ""

# Check if logged in
if ! railway whoami &>/dev/null; then
    echo "❌ Not logged into Railway"
    echo "Please run: railway login"
    exit 1
fi

echo "✅ Logged into Railway"
echo ""

# Query database
echo "📊 Database Statistics:"
echo ""

railway run sqlite3 database.sqlite <<EOF
SELECT '👥 Users: ' || COUNT(*) FROM users;
SELECT '📱 Devices: ' || COUNT(*) FROM devices;
SELECT '💬 Conversations: ' || COUNT(*) FROM conversations;
SELECT '📝 Messages: ' || COUNT(*) FROM messages;
EOF

echo ""
echo "📋 Recent Users:"
railway run sqlite3 database.sqlite -header -column "SELECT id, apple_user_id, email, created_at FROM users ORDER BY created_at DESC LIMIT 5;"

echo ""
echo "📋 Recent Conversations:"
railway run sqlite3 database.sqlite -header -column "SELECT c.id, c.title, c.created_at, COUNT(m.id) as message_count FROM conversations c LEFT JOIN messages m ON c.id = m.conversation_id GROUP BY c.id ORDER BY c.created_at DESC LIMIT 5;"

echo ""
echo "💡 To download database and view in Prisma Studio, run:"
echo "   ./download-railway-db.sh"

