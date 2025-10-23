# ChatOnWrist Backend Deployment Guide

## Option 1: Railway (Recommended)

### Step 1: Create Railway Account
1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub
3. Connect your GitHub account

### Step 2: Deploy to Railway
1. **Push your code to GitHub:**
   ```bash
   cd /Users/david/Desktop/ChatOnWrist
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/ChatOnWrist.git
   git push -u origin main
   ```

2. **Deploy on Railway:**
   - Go to Railway dashboard
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your ChatOnWrist repository
   - Railway will automatically detect it's a Node.js app

### Step 3: Configure Environment Variables
In Railway dashboard, add these environment variables:
- `OPENAI_API_KEY` = your OpenAI API key
- `JWT_SECRET` = a random secret string
- `NODE_ENV` = production

### Step 4: Get Your Backend URL
Railway will give you a URL like: `https://chatonwrist-production.up.railway.app`

## Option 2: Heroku

### Step 1: Install Heroku CLI
```bash
brew install heroku/brew/heroku
```

### Step 2: Deploy to Heroku
```bash
cd /Users/david/Desktop/ChatOnWrist/backend
heroku create chatonwrist-backend
heroku config:set OPENAI_API_KEY=your_openai_key
heroku config:set JWT_SECRET=your_jwt_secret
git add .
git commit -m "Deploy to Heroku"
git push heroku main
```

## Option 3: Vercel (Serverless)

### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

### Step 2: Deploy
```bash
cd /Users/david/Desktop/ChatOnWrist/backend
vercel
```

## Update iOS App

Once you have your backend URL, update the iOS app:

```swift
// In AppConfig.swift
static let backendBaseURL = "https://your-backend-url.com"
```

## Database Options

### Option 1: Railway PostgreSQL (Free)
Railway provides free PostgreSQL database.

### Option 2: Supabase (Free)
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Get connection string
4. Update backend to use PostgreSQL

### Option 3: PlanetScale (Free)
1. Go to [planetscale.com](https://planetscale.com)
2. Create database
3. Get connection string
4. Update backend

## Recommended Setup

**For production, I recommend:**
- **Backend:** Railway (free tier)
- **Database:** Railway PostgreSQL (free tier)
- **Domain:** Custom domain (optional)

This gives you a fully functional production backend for free!
