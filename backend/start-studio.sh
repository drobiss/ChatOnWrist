#!/bin/bash

# Start Prisma Studio with correct database path
cd "$(dirname "$0")"

export DATABASE_URL="file:$(pwd)/database.sqlite"

echo "🚀 Starting Prisma Studio..."
echo "📁 Database: $DATABASE_URL"
echo "🌐 Opening at: http://localhost:5555"
echo ""
echo "Press Ctrl+C to stop"
echo ""

npx prisma studio --port 5555




