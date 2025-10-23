const fs = require('fs');
const path = require('path');

// Create .env file from template
const envContent = `# Server Configuration
PORT=3000
NODE_ENV=development

# JWT Secret for token signing
JWT_SECRET=chatonwrist_super_secret_jwt_key_2025

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4o
OPENAI_MAX_TOKENS=150
OPENAI_TEMPERATURE=0.7

# Apple Sign In Configuration (for future implementation)
APPLE_TEAM_ID=your_apple_team_id
APPLE_CLIENT_ID=com.davidbrezina.ChatOnWrist
APPLE_KEY_ID=your_apple_key_id

# Database
DATABASE_PATH=./database.sqlite

# Rate Limiting
RATE_LIMIT_WINDOW_MS=3600000
RATE_LIMIT_MAX_REQUESTS=100
`;

fs.writeFileSync('.env', envContent);
console.log('✅ .env file created');

// Create README for backend
const readmeContent = `# ChatOnWrist Backend

A Node.js backend server for the ChatOnWrist iOS app.

## Setup

1. Install dependencies:
\`\`\`bash
npm install
\`\`\`

2. Start the server:
\`\`\`bash
npm start
\`\`\`

For development with auto-restart:
\`\`\`bash
npm run dev
\`\`\`

## API Endpoints

- \`GET /health\` - Health check
- \`POST /auth/apple\` - Apple Sign In authentication
- \`POST /device/pair\` - Pair device with user
- \`POST /device/generate-pairing-code\` - Generate pairing code
- \`POST /chat/message\` - Send chat message
- \`GET /chat/conversations\` - Get conversations
- \`GET /chat/conversations/:id\` - Get specific conversation

## Environment Variables

Copy \`env.example\` to \`.env\` and configure:

- \`OPENAI_API_KEY\` - Your OpenAI API key
- \`JWT_SECRET\` - Secret for JWT token signing
- \`PORT\` - Server port (default: 3000)

## Database

The server uses SQLite database that will be created automatically on first run.

## Testing

Test the health endpoint:
\`\`\`bash
curl http://localhost:3000/health
\`\`\`
`;

fs.writeFileSync('README.md', readmeContent);
console.log('✅ README.md created');

console.log('\\n🚀 Backend setup complete!');
console.log('Run: npm install && npm start');