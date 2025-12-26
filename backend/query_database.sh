#!/bin/bash

# Script to query the ChatOnWrist database
# Usage: ./query_database.sh

DB_PATH="./database.sqlite"

echo "=== ChatOnWrist Database Query Tool ==="
echo ""

if [ ! -f "$DB_PATH" ]; then
    echo "❌ Database not found at: $DB_PATH"
    echo "   Make sure you're running this from the backend directory"
    exit 1
fi

echo "📊 Database Statistics:"
echo ""

# Count users
USERS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM users;")
echo "👥 Total Users: $USERS"

# Count devices
DEVICES=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM devices;")
echo "📱 Total Devices: $DEVICES"

# Count conversations
CONVERSATIONS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM conversations;")
echo "💬 Total Conversations: $CONVERSATIONS"

# Count messages
MESSAGES=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM messages;")
echo "📝 Total Messages: $MESSAGES"

echo ""
echo "=== Users ==="
sqlite3 "$DB_PATH" -header -column "SELECT id, apple_user_id, email, created_at FROM users LIMIT 10;"

echo ""
echo "=== Devices ==="
sqlite3 "$DB_PATH" -header -column "SELECT d.id, d.device_type, d.device_token, u.email as user_email, d.created_at FROM devices d LEFT JOIN users u ON d.user_id = u.id LIMIT 10;"

echo ""
echo "=== Recent Conversations ==="
sqlite3 "$DB_PATH" -header -column "SELECT c.id, c.title, d.device_type, u.email as user_email, c.created_at FROM conversations c LEFT JOIN devices d ON c.device_id = d.id LEFT JOIN users u ON d.user_id = u.id ORDER BY c.created_at DESC LIMIT 10;"

echo ""
echo "=== Recent Messages ==="
sqlite3 "$DB_PATH" -header -column "SELECT m.id, m.content, m.is_from_user, c.title as conversation, m.created_at FROM messages m LEFT JOIN conversations c ON m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 10;"



