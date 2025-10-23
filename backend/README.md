# ChatOnWrist Backend

A Node.js backend server for the ChatOnWrist iOS app.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

For development with auto-restart:
```bash
npm run dev
```

## API Endpoints

- `GET /health` - Health check
- `POST /auth/apple` - Apple Sign In authentication
- `POST /device/pair` - Pair device with user
- `POST /device/generate-pairing-code` - Generate pairing code
- `POST /chat/message` - Send chat message
- `GET /chat/conversations` - Get conversations
- `GET /chat/conversations/:id` - Get specific conversation

## Environment Variables

Copy `env.example` to `.env` and configure:

- `OPENAI_API_KEY` - Your OpenAI API key
- `JWT_SECRET` - Secret for JWT token signing
- `PORT` - Server port (default: 3000)

## Database

The server uses SQLite database that will be created automatically on first run.

## Testing

Test the health endpoint:
```bash
curl http://localhost:3000/health
```
