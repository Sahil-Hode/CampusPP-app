# JNEXIA Voice Chat Backend

Backend server for voice chat functionality with 3D mentor integration.

## Features

- 🎤 **Real-time Voice Chat** via Socket.IO
- 🗣️ **Speech-to-Text** using Google Cloud Speech-to-Text API
- 🤖 **AI Responses** powered by Mistral AI
- 🔊 **Text-to-Speech** using ElevenLabs API
- 🌍 **Multi-Language Support** (English, Hindi, Marathi, Spanish, French, German, Japanese, Chinese)
- 💾 **Session Management** with conversation history

## Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Create a `.env` file in the backend directory:

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:

```env
MISTRAL_API_KEY=your_mistral_api_key
ELEVENLABS_API_KEY=your_elevenlabs_api_key
ELEVENLABS_VOICE_ID=pNInz6obpgDQGcFmaJgB
PORT=3000
NODE_ENV=development
GOOGLE_APPLICATION_CREDENTIALS=./google-credentials.json
```

### 3. Google Cloud Setup

1. Create a Google Cloud project
2. Enable the Speech-to-Text API
3. Create a service account and download the JSON credentials
4. Save the credentials file as `google-credentials.json` in the backend directory

### 4. Start the Server

Development mode (with auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

The server will start on `http://localhost:3000`

## API Endpoints

### Health Check
```
GET /health
```
Returns server status and configuration.

### Chat API (Testing)
```
POST /api/chat
Content-Type: application/json

{
  "message": "Hello, how are you?",
  "sessionId": "optional-session-id"
}
```

### Text-to-Speech API (Testing)
```
POST /api/tts
Content-Type: application/json

{
  "text": "Hello, this is a test"
}
```

## Socket.IO Events

### Client → Server

#### `audioStream`
Send audio chunks during recording.
```javascript
socket.emit('audioStream', audioData);
```

#### `stopAudio`
Stop recording and process audio.
```javascript
socket.emit('stopAudio', {
  encoding: 'WEBM_OPUS',
  sampleRateHertz: 48000,
  languageCode: 'en-US',
  systemPrompt: 'You are a helpful teacher',
  studentContext: 'Student data...'
});
```

#### `textMessage`
Send text message (for testing).
```javascript
socket.emit('textMessage', {
  message: 'Hello',
  languageCode: 'en-US',
  systemPrompt: 'You are a helpful teacher',
  studentContext: 'Student data...'
});
```

#### `clearHistory`
Clear conversation history.
```javascript
socket.emit('clearHistory');
```

### Server → Client

#### `connected`
Connection confirmation.
```javascript
socket.on('connected', (data) => {
  // data.sessionId, data.message
});
```

#### `transcription`
Speech-to-text result.
```javascript
socket.on('transcription', (data) => {
  // data.text
});
```

#### `aiResponse`
Complete AI response with audio.
```javascript
socket.on('aiResponse', (data) => {
  // data.transcription - original text
  // data.response - AI response text
  // data.audio - base64 encoded audio
});
```

#### `error`
Error notification.
```javascript
socket.on('error', (data) => {
  // data.message
});
```

#### `historyCleared`
History cleared confirmation.
```javascript
socket.on('historyCleared', (data) => {
  // data.message
});
```

## Project Structure

```
backend/
├── services/
│   ├── speechToText.service.js   # Google Speech-to-Text
│   ├── mistralBot.service.js     # Mistral AI
│   └── elevenLabs.service.js     # ElevenLabs TTS
├── sockets/
│   └── voiceChat.socket.js       # Socket.IO handlers
├── data/
│   └── mistral_history.json      # Conversation history
├── .env                          # Environment variables
├── .gitignore                    # Git ignore file
├── package.json                  # Dependencies
├── server.js                     # Main server
└── README.md                     # This file
```

## Troubleshooting

### Google Cloud Authentication Error
- Ensure `google-credentials.json` exists in the backend directory
- Verify the file path in `.env` is correct
- Check that Speech-to-Text API is enabled in your Google Cloud project

### Mistral AI Error
- Verify your API key is correct
- Check your API quota and usage limits

### ElevenLabs Error
- Verify your API key is correct
- Check your character quota (free tier has limits)

### Socket Connection Failed
- Ensure the server is running
- Check firewall settings
- Verify the correct port is being used

## License

Part of JNEXIA Project
