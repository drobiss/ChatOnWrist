# ChatOnWrist Backend Setup

## Quick Start

1. **Navigate to backend directory:**
   ```bash
   cd /Users/david/Desktop/ChatOnWrist/backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Setup environment:**
   ```bash
   node setup.js
   ```

4. **Start the server:**
   ```bash
   npm start
   ```

The server will run on `http://localhost:3000`

## Testing the Backend

### Health Check
```bash
curl http://localhost:3000/health
```

### Test Authentication (Mock)
```bash
curl -X POST http://localhost:3000/auth/apple \
  -H "Content-Type: application/json" \
  -d '{"appleIDToken": "mock_token"}'
```

### Test Device Pairing
1. First get a user token from authentication
2. Generate a pairing code:
```bash
curl -X POST http://localhost:3000/device/generate-pairing-code \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json"
```

3. Pair a device:
```bash
curl -X POST http://localhost:3000/device/pair \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pairingCode": "123456", "deviceType": "iphone"}'
```

### Test Chat
```bash
curl -X POST http://localhost:3000/chat/message \
  -H "Authorization: Bearer YOUR_DEVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, how are you?"}'
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/auth/apple` | Apple Sign In authentication |
| POST | `/device/generate-pairing-code` | Generate pairing code |
| POST | `/device/pair` | Pair device with user |
| POST | `/chat/message` | Send chat message |
| GET | `/chat/conversations` | Get conversations |
| GET | `/chat/conversations/:id` | Get specific conversation |

## Database

The server uses SQLite database (`database.sqlite`) that is created automatically.

### Tables:
- `users` - User accounts
- `devices` - Paired devices
- `conversations` - Chat conversations
- `messages` - Chat messages
- `pairing_codes` - Temporary pairing codes

## Development

For development with auto-restart:
```bash
npm run dev
```

## Production Deployment

For production, you'll need to:
1. Set up a proper domain (e.g., `api.chatonwrist.com`)
2. Use HTTPS
3. Set up proper Apple Sign In verification
4. Use a production database (PostgreSQL, MySQL)
5. Set up proper environment variables
6. Configure CORS for your domain

## Troubleshooting

### Common Issues:

1. **Port already in use:**
   - Change PORT in .env file
   - Kill process using port 3000: `lsof -ti:3000 | xargs kill -9`

2. **OpenAI API errors:**
   - Check your OpenAI API key
   - Verify you have credits in your OpenAI account

3. **Database errors:**
   - Delete `database.sqlite` and restart server
   - Check file permissions

4. **CORS errors:**
   - Make sure your iOS app is using the correct backend URL
   - Check CORS configuration in server.js
