# Railway PostgreSQL Setup

## The Problem
Your logs show `DATABASE_URL: NOT SET` - Railway isn't passing the PostgreSQL connection string to your backend.

## Solution: Link PostgreSQL to Backend Service

Railway sets `DATABASE_URL` automatically when PostgreSQL is **linked** to your backend service.

### Steps:

1. **Go to Railway Dashboard** → Your Project

2. **Click on your PostgreSQL service** (the database service)

3. **Click "Settings" tab**

4. **Under "Connected Services"** → Click **"+ Connect Service"**

5. **Select your backend service** (the one running `server.js`)

6. **Railway will automatically:**
   - Set `DATABASE_URL` environment variable in your backend service
   - Link the services together

### Alternative: Manual Setup

If linking doesn't work:

1. **Go to Railway Dashboard** → Your Project → **Backend Service**

2. **Click "Variables" tab**

3. **Click "+ New Variable"**

4. **Name:** `DATABASE_URL`
   **Value:** Copy from PostgreSQL service → Settings → Connection → `DATABASE_URL`

5. **Click "Add"**

### Verify

After linking/setting, redeploy and check logs:
- Should see: `📊 DATABASE_URL: postgresql://...`
- Should see: `📊 Using PostgreSQL with Prisma...`



