require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const path = require('path');

// Import socket handlers
const initializeVoiceChatSocket = require('./sockets/voiceChat.socket');

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize Socket.IO with CORS
const io = new Server(server, {
    cors: {
        origin: '*', // Allow all origins for development
        methods: ['GET', 'POST'],
    },
    maxHttpBufferSize: 10e6, // 10MB for audio chunks
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        message: 'Voice chat server is running',
        timestamp: new Date().toISOString(),
    });
});

// API endpoint to test Mistral AI
app.post('/api/chat', async (req, res) => {
    try {
        const { message, sessionId = 'test-session' } = req.body;

        if (!message) {
            return res.status(400).json({ error: 'Message is required' });
        }

        const mistralBotService = require('./services/mistralBot.service');
        const response = await mistralBotService.generateResponse(message, sessionId);

        res.json({ response });
    } catch (error) {
        console.error('[API] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// API endpoint to test Text-to-Speech
app.post('/api/tts', async (req, res) => {
    try {
        const { text } = req.body;

        if (!text) {
            return res.status(400).json({ error: 'Text is required' });
        }

        const elevenLabsService = require('./services/elevenLabs.service');
        const audioBuffer = await elevenLabsService.textToSpeech(text);

        res.set('Content-Type', 'audio/mpeg');
        res.send(audioBuffer);
    } catch (error) {
        console.error('[API] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// Initialize Socket.IO handlers
initializeVoiceChatSocket(io);

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log('='.repeat(50));
    console.log('🚀 Voice Chat Server Started');
    console.log('='.repeat(50));
    console.log(`📡 Server running on: http://localhost:${PORT}`);
    console.log(`🔌 Socket.IO ready for connections`);
    console.log(`🎤 Google Speech-to-Text: ${process.env.GOOGLE_APPLICATION_CREDENTIALS ? '✓' : '✗'}`);
    console.log(`🤖 Mistral AI: ${process.env.MISTRAL_API_KEY ? '✓' : '✗'}`);
    console.log(`🔊 ElevenLabs TTS: ${process.env.ELEVENLABS_API_KEY ? '✓' : '✗'}`);
    console.log('='.repeat(50));
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('\nSIGINT received, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});
