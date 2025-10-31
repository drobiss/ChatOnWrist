# ChatOnWrist

An AI Chat app for Apple Watch with voice control and an iOS companion app.

## Features

### iOS App
- **Tab Bar Navigation**: Chat, History, Settings
- **Sign in with Apple**: Secure authentication
- **Chat Interface**: Text input with AI responses
- **History**: View and continue previous conversations
- **Settings**: User preferences and app configuration

### Apple Watch App
- **Voice-Controlled**: Dictate questions, get spoken responses
- **Minimal Interface**: Chat and History buttons
- **TTS Integration**: Text-to-speech for AI responses
- **Device Pairing**: Secure connection to iPhone

## Setup Instructions

### 1. OpenAI API Key
1. Get your OpenAI API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Open `ChatOnWrist/Configuration/AppConfig.swift`
3. Replace `"your-openai-api-key-here"` with your actual API key

### 2. Xcode Configuration
1. Open `ChatOnWrist.xcodeproj` in Xcode
2. Select your development team
3. Configure signing for both iOS and watchOS targets
4. Build and run on device (simulator works for basic testing)

### 3. Required Capabilities
- **Sign in with Apple**: Enable in Xcode capabilities
- **Speech Recognition**: For voice input on watch
- **Microphone**: For voice recording
- **Keychain Sharing**: For secure token storage

### 4. Testing
1. **iOS**: Run on iPhone, sign in with Apple
2. **Watch**: Pair with iPhone, enter pairing code "1234" (demo)
3. **Voice**: Test voice input and TTS on watch

## Architecture

### Data Models
- `Conversation`: Chat sessions with messages
- `Message`: Individual chat messages (user/AI)

### Services
- `OpenAIService`: API integration with GPT-4o
- `AuthenticationService`: Sign in with Apple + device pairing
- `ConversationStore`: Local conversation storage
- `KeychainService`: Secure token storage

### Key Features
- **Voice Recognition**: Speech-to-text on watch
- **Text-to-Speech**: AI responses read aloud
- **Offline Storage**: Conversations saved locally
- **Secure Auth**: JWT tokens for API access
- **Cross-Platform**: Shared data between iOS and watch

## Development Notes

- Uses latest SwiftUI and Swift features
- Optimized for Apple Watch screen sizes
- Battery-conscious design for watch
- Follows Apple Human Interface Guidelines
- Supports both light and dark modes

## Next Steps

1. Add real speech recognition (Speech framework)
2. Implement backend API for conversation sync
3. Add push notifications for new messages
4. Enhance voice recognition accuracy
5. Add conversation search and filtering

# ChatOnWrist
# ChatOnWrist


