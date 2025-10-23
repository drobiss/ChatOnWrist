# 🚀 Production Deployment Guide

## Deploy Your Backend to Railway (Free)

### Step 1: Create Railway Account
1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub
3. Connect your ChatOnWrist repository

### Step 2: Deploy Backend
1. In Railway dashboard, click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose your ChatOnWrist repository
4. Select the `backend` folder as root directory

### Step 3: Set Environment Variables
In Railway dashboard, go to your project → Variables tab and add:

```
OPENAI_API_KEY=your_openai_api_key_here
JWT_SECRET=chatonwrist_super_secret_jwt_key_2025_production
NODE_ENV=production
PORT=3000
```

### Step 4: Get Production URL
1. Railway will give you a URL like: `https://chatonwrist-production.up.railway.app`
2. Copy this URL

### Step 5: Update iOS App
Update the production URL in your iOS app:

**File: `ChatOnWrist/Configuration/AppConfig.swift`**
```swift
static let backendBaseURL = "https://YOUR_RAILWAY_URL.up.railway.app"
```

## 🎯 How It Works for App Store Users

### ✅ **For Your App Store Users:**
1. **No API keys needed** - Your backend handles all OpenAI calls
2. **Secure** - API key stays on your server
3. **Free for users** - They don't need OpenAI accounts
4. **Scalable** - You control usage and costs

### 🔧 **Architecture:**
```
App Store User → Your iOS App → Your Backend Server → OpenAI API
                     ↓
              (No API key needed)
```

### 💰 **Cost Management:**
- You pay for OpenAI API usage
- You can add usage limits per user
- You can add premium features later

## 🚀 Alternative: Deploy to Heroku

If you prefer Heroku:

### Step 1: Install Heroku CLI
```bash
brew install heroku/brew/heroku
```

### Step 2: Login and Deploy
```bash
cd backend
heroku login
heroku create chatonwrist-backend
heroku config:set OPENAI_API_KEY=your_openai_api_key_here
git push heroku main
```

## 📱 Update Your iOS App

After getting your production URL, update:

**File: `ChatOnWrist/Configuration/AppConfig.swift`**
```swift
#if DEBUG
static let backendBaseURL = "http://127.0.0.1:3000" // Local development
#else
static let backendBaseURL = "https://YOUR_PRODUCTION_URL" // Production
#endif
```

## ✅ Test Production

1. Deploy backend to Railway/Heroku
2. Update iOS app with production URL
3. Test on device (not simulator)
4. Submit to App Store

## 🎉 Result

Your app will work for ALL App Store users without them needing:
- OpenAI accounts
- API keys
- Any setup

They just download and use! 🚀
