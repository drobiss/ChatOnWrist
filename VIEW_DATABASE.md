# How to View Railway PostgreSQL Database

## Option 1: Railway Web Dashboard (Easiest!)

1. Go to **Railway Dashboard** → Your Project
2. Click on your **PostgreSQL service**
3. Click **"Data"** tab
4. View/edit all tables directly in the browser! 🎉

## Option 2: Admin API Endpoint

Your backend has an admin endpoint that shows all database data:

```
https://your-app.railway.app/admin/dashboard?key=YOUR_ADMIN_KEY
```

**To get your ADMIN_KEY:**
1. Railway Dashboard → Backend Service → Variables
2. Find `ADMIN_KEY` (or create one if it doesn't exist)

**The endpoint shows:**
- User count, device count, conversations, messages
- All users with emails
- All devices
- All conversations with message counts
- Recent messages

## Option 3: Prisma Studio (Local)

Connect Prisma Studio to your Railway database:

1. **Get DATABASE_URL from Railway:**
   - Railway Dashboard → PostgreSQL Service → Settings → Connection
   - Copy the `DATABASE_URL`

2. **Set it locally:**
   ```bash
   cd backend
   export DATABASE_URL="postgresql://..." # Paste your Railway DATABASE_URL
   npx prisma studio
   ```

3. **Open** http://localhost:5555 in your browser

## Option 4: Railway CLI

```bash
# Install Railway CLI
npm i -g @railwayapp/cli

# Login
railway login

# Link to your project
railway link

# Query database
railway run psql $DATABASE_URL -c "SELECT * FROM users;"
```

## Option 5: Database Client (TablePlus, DBeaver, etc.)

1. Get connection details from Railway:
   - Railway Dashboard → PostgreSQL Service → Settings → Connection
   - Copy: Host, Port, Database, User, Password

2. Connect using any PostgreSQL client:
   - **TablePlus** (Mac/Windows)
   - **DBeaver** (Free, cross-platform)
   - **pgAdmin** (Free)
   - **Postico** (Mac)

---

**Recommended:** Start with Option 1 (Railway Dashboard) - it's the easiest!

