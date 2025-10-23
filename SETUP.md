# ChatOnWrist Setup Guide

## Prerequisites
- Xcode 15.0+
- Node.js 18+
- OpenAI API Key

## Setup Instructions

### 1. Configure API Keys

**In `ChatOnWrist/Configuration/AppConfig.swift`:**
```swift
static let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
```

**In `ChatOnWristWatch Watch App/Configuration/AppConfig.swift`:**
```swift
static let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
```

### 2. Backend Setup

**Navigate to backend directory:**
```bash
cd backend
npm install
```

**Create environment file:**
```bash
cp env.example .env
```

**Edit `.env` file with your API keys:**
```
OPENAI_API_KEY=your_actual_openai_api_key
JWT_SECRET=your_jwt_secret_here
```

**Start backend server:**
```bash
npm start
```

### 3. iOS App Setup

1. Open `ChatOnWrist.xcodeproj` in Xcode
2. Update API keys in AppConfig.swift files
3. Build and run the app

### 4. Production Deployment

See `backend/DEPLOYMENT.md` for deployment instructions.

## Security Note

Never commit API keys to version control. Use environment variables or secure configuration management.
