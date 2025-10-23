# ChatOnWrist Backend API Documentation

## Base URL
```
https://api.chatonwrist.com
```

## Authentication
All endpoints (except `/auth/apple`) require a Bearer token in the Authorization header:
```
Authorization: Bearer <token>
```

## Endpoints

### 1. Authentication

#### POST /auth/apple
Authenticate user with Apple Sign In token.

**Request:**
```json
{
  "appleIDToken": "string"
}
```

**Response:**
```json
{
  "userToken": "string",
  "userId": "string", 
  "expiresAt": "2025-12-31T23:59:59Z"
}
```

### 2. Device Pairing

#### POST /device/pair
Pair a device (iPhone/Watch) with a user account.

**Request:**
```json
{
  "pairingCode": "string"
}
```

**Response:**
```json
{
  "deviceToken": "string",
  "deviceId": "string",
  "expiresAt": "2025-12-31T23:59:59Z"
}
```

### 3. Chat

#### POST /chat/message
Send a message and get AI response.

**Request:**
```json
{
  "message": "string",
  "conversationId": "string" // optional, null for new conversation
}
```

**Response:**
```json
{
  "response": "string",
  "conversationId": "string",
  "messageId": "string"
}
```

#### GET /chat/conversations
Get all conversations for the device.

**Response:**
```json
[
  {
    "id": "string",
    "title": "string",
    "lastMessage": "string",
    "createdAt": "2025-10-22T10:00:00Z",
    "updatedAt": "2025-10-22T10:30:00Z",
    "messages": [
      {
        "id": "string",
        "content": "string",
        "isFromUser": true,
        "timestamp": "2025-10-22T10:00:00Z"
      }
    ]
  }
]
```

#### GET /chat/conversations/{id}
Get a specific conversation.

**Response:** Same as conversation object in the array above.

## Error Responses

All endpoints return errors in this format:
```json
{
  "message": "string",
  "code": "string"
}
```

## HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

## Implementation Notes

1. **Apple Sign In**: The backend should verify the Apple ID token with Apple's servers
2. **Device Pairing**: Generate secure pairing codes (6-8 digits) that expire after 5 minutes
3. **Chat Messages**: Use OpenAI API with the configured model and settings
4. **Token Management**: User tokens expire after 24 hours, device tokens after 7 days
5. **Rate Limiting**: Implement rate limiting for chat endpoints (e.g., 100 messages per hour)
6. **Security**: Use HTTPS, validate all inputs, implement proper CORS headers

## Required Environment Variables

```bash
OPENAI_API_KEY=your_openai_api_key
JWT_SECRET=your_jwt_secret_key
DATABASE_URL=your_database_connection_string
```

## Database Schema

### Users Table
- id (UUID, primary key)
- apple_user_id (string, unique)
- email (string, nullable)
- created_at (timestamp)
- updated_at (timestamp)

### Devices Table  
- id (UUID, primary key)
- user_id (UUID, foreign key)
- device_type (enum: 'iphone', 'watch')
- device_token (string, unique)
- created_at (timestamp)
- updated_at (timestamp)

### Conversations Table
- id (UUID, primary key)
- device_id (UUID, foreign key)
- title (string)
- created_at (timestamp)
- updated_at (timestamp)

### Messages Table
- id (UUID, primary key)
- conversation_id (UUID, foreign key)
- content (text)
- is_from_user (boolean)
- created_at (timestamp)
