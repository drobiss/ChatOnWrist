# ChatOnWrist Setup Guide

## 🔑 API Key Configuration

### Step 1: Get Your OpenAI API Key
1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create a new API key
3. Copy the key (starts with `sk-`)

### Step 2: Configure iOS App
**Replace the API key in these files:**

**File: `ChatOnWrist/Configuration/AppConfig.swift`**
```swift
static let openAIAPIKey = "YOUR_ACTUAL_OPENAI_API_KEY_HERE"
```

**File: `ChatOnWristWatch Watch App/Configuration/AppConfig.swift`**
```swift
static let openAIAPIKey = "YOUR_ACTUAL_OPENAI_API_KEY_HERE"
```

### Step 3: Configure Backend
**File: `backend/.env`**
```bash
OPENAI_API_KEY=your_actual_openai_api_key_here
JWT_SECRET=chatonwrist_super_secret_jwt_key_2025
```

## 🚀 Development Setup

### Local Development
1. **Start backend server:**
   ```bash
   cd backend
   npm install
   node setup.js
   npm start
   ```

2. **Run iOS app in Xcode**
3. **App will connect to local backend automatically**

### Production Deployment
1. **Deploy backend to Railway/Heroku**
2. **Update backend URL in AppConfig.swift for production**
3. **Build and deploy iOS app**

## 🔒 Security Notes

- ✅ **API keys are now safe for GitHub** - No real keys in code
- ✅ **Environment variables** - Backend uses .env file
- ✅ **Debug/Release builds** - Different backend URLs
- ✅ **Keychain storage** - Secure token storage

## 📱 Testing

1. **Sign in with Apple** (mock authentication for now)
2. **Test chat functionality**
3. **Check backend connection in Settings**

## 🎯 Next Steps

1. **Add your OpenAI API key to the files above**
2. **Test the app locally**
3. **Deploy backend to production**
4. **Update production backend URL**

**Your app is now ready for development and production!** 🎉
