#!/bin/bash

# Script to download database from Railway and view with Prisma Studio

echo "📥 Downloading database from Railway..."
echo ""

# Download database file from Railway
railway run cat database.sqlite > railway-database.sqlite 2>&1

if [ -f "railway-database.sqlite" ] && [ -s "railway-database.sqlite" ]; then
    echo "✅ Database downloaded successfully!"
    echo ""
    
    # Update .env to use Railway database
    echo 'DATABASE_URL="file:./railway-database.sqlite"' > .env
    echo "📝 Updated .env to use Railway database"
    echo ""
    
    # Generate Prisma client
    echo "🔄 Generating Prisma Client..."
    npx prisma generate
    
    echo ""
    echo "🚀 Starting Prisma Studio..."
    echo "📊 Open http://localhost:5555 in your browser"
    echo ""
    
    npx prisma studio --port 5555
else
    echo "❌ Failed to download database"
    echo ""
    echo "Make sure you:"
    echo "1. Are logged in: railway login"
    echo "2. Are linked to project: railway link"
    echo "3. Railway service has the database file"
    exit 1
fi

