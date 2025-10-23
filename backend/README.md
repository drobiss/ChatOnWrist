# ChatOnWrist Backend

Backend server for the ChatOnWrist iOS app.

## Quick Start

```bash
npm install
npm start
```

## Environment Variables

Set these in Railway/Heroku dashboard:

- `OPENAI_API_KEY` - Your OpenAI API key
- `JWT_SECRET` - Secret for JWT tokens
- `NODE_ENV` - Set to "production"
- `PORT` - Railway/Heroku will set this automatically

## API Endpoints

- `GET /health` - Health check
- `POST /auth/apple` - Apple Sign In
- `POST /device/pair` - Pair device
- `POST /chat/message` - Send message
- `GET /chat/conversations` - Get conversations

## Deployment

This backend is designed to be deployed to Railway or Heroku.