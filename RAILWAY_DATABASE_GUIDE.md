# How to View Railway Database

Since your backend runs on Railway, the database is stored on Railway's servers. Here are ways to view it:

## Option 1: Railway CLI (Easiest)

### Step 1: Install Railway CLI (if not already installed)
```bash
npm install -g @railway/cli
```

### Step 2: Login to Railway
```bash
railway login
```

### Step 3: Link to your project
```bash
cd /Users/david/Desktop/ChatOnWrist/backend
railway link
```

### Step 4: Download the database file
```bash
# Download database.sqlite from Railway
railway run cat database.sqlite > railway-database.sqlite
```

### Step 5: View with Prisma Studio
```bash
# Update .env to point to downloaded database
echo 'DATABASE_URL="file:./railway-database.sqlite"' > .env
npx prisma studio
```

## Option 2: Railway Web Dashboard

1. Go to https://railway.app
2. Select your project
3. Click on your service
4. Go to "Variables" tab
5. Look for database-related variables
6. Railway might have a "Data" or "Database" tab with a viewer

## Option 3: Add Admin Endpoint (Best for ongoing use)

Add an admin endpoint to your backend that shows database data via API.

## Option 4: Use Railway's Database Service

If Railway provides a PostgreSQL database service, you can:
1. Add PostgreSQL service in Railway
2. Update your backend to use PostgreSQL
3. Connect Prisma Studio to PostgreSQL

## Quick Check: What's in Railway Database?

You can check Railway logs to see if data is being saved:
1. Go to Railway dashboard
2. Click your service
3. Go to "Deployments" → Click latest deployment → "Logs"
4. Look for "INSERT INTO users" or similar messages



