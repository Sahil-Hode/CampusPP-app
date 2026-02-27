# Voice Chat — Full API & Configuration Reference

Complete reference for the real-time Voice Chat system — Socket.IO events, request/response payloads, audio pipeline, TTS config, and frontend integration.

> **Note:** This doc covers the **general Voice Chat** system (root Socket.IO namespace). The **Mock Interview** system is a separate Socket.IO namespace (`/mock-interview`) with different events — see `docs-mock-interview-api.md`.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Connection Setup](#connection-setup)
3. [Socket.IO Events — Client → Server](#client-to-server-events)
4. [Socket.IO Events — Server → Client](#server-to-client-events)
5. [Full Request/Response Flow](#full-request-response-flow)
6. [Audio Pipeline Details](#audio-pipeline-details)
7. [TTS Configuration (Text-to-Speech)](#tts-configuration)
8. [STT Configuration (Speech-to-Text)](#stt-configuration)
9. [Silence Detection Settings](#silence-detection-settings)
10. [Frontend Integration Code](#frontend-integration-code)
11. [Supported Languages](#supported-languages)
12. [Error Handling](#error-handling)

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│  BROWSER (Frontend)                                                  │
│                                                                      │
│  Mic → Web Audio API (16kHz, mono) → ScriptProcessor → audioData ──┐│
│                                                                     ││
│  AnalyserNode → RMS volume → Silence detection (2s auto-stop)      ││
│                                                                     ││
│  <audio> player ← ttsAudio (base64 WAV/MP3) ← ─ ─ ─ ─ ─ ─ ─ ─ ┐ ││
└──────────────────────────────────────────────────────────────┤   │──┘│
                                                               │   │   │
                        Socket.IO (WebSocket)                  │   │   │
                                                               ▼   │   │
┌──────────────────────────────────────────────────────────────────────┐
│  SERVER (Node.js)                                                    │
│                                                                      │
│  audioData ─→ Google Cloud STT (Streaming) ─→ transcription         │
│                                                                      │
│  stopStream ─→ finalTranscript ─→ Mistral AI ─→ aiResponse         │
│                                                                      │
│  aiResponse text ─→ Gemini TTS (Vindemiatrix) ─→ ttsAudio          │
│                     ↓ (if fails, retry once)                        │
│                     ↓ (fallback: Google Cloud TTS Wavenet-F)        │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Connection Setup

### URL

```
ws://localhost:3000    (Socket.IO auto-negotiates transport)
```

Frontend page: `http://localhost:3000/voice-chat`

### Client Connection

```javascript
const socket = io('http://localhost:3000', {
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionAttempts: 5
});
```

### Server Config

```javascript
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    },
    maxHttpBufferSize: 1e8   // 100 MB — handles large audio chunks
});
```

### On Connect, Server Emits

```javascript
// Event: 'connected'
{
    message: "Connected to Speech-to-Text AI Server",
    sessionId: "socket-id-here"    // unique per connection, used for chat history
}
```

---

## Client to Server Events

### 1. `startStream` — Begin Live Audio Streaming

Starts a Google Cloud Speech-to-Text streaming recognition session.

```javascript
socket.emit('startStream', {
    encoding: 'LINEAR16',       // required, must match audio format
    sampleRateHertz: 16000,     // required, must match AudioContext sample rate
    languageCode: 'en-US'       // optional, default: 'en-US'
});
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `encoding` | string | No | `LINEAR16` | Audio encoding format |
| `sampleRateHertz` | number | No | `16000` | Sample rate in Hz |
| `languageCode` | string | No | `en-US` | BCP-47 language code |

**Server responds with:** `streamStarted`

---

### 2. `audioData` — Send Audio Chunk

Send raw PCM audio data in real-time while the stream is active.

```javascript
// Send Int16Array buffer directly
socket.emit('audioData', int16Array.buffer);
```

| Field | Type | Description |
|-------|------|-------------|
| `audioData` | ArrayBuffer | Raw LINEAR16 PCM audio, 16-bit signed integers, mono, 16kHz |

**No response event.** Server writes directly to Google Cloud STT stream. Transcription results come back via `transcription` events.

---

### 3. `stopStream` — Stop Streaming & Get AI Response

Ends the STT stream, sends accumulated transcript to Mistral AI, and triggers TTS.

```javascript
socket.emit('stopStream', {
    languageCode: 'en-US',              // optional
    systemPrompt: 'You are a helpful AI assistant.'  // optional
});
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `languageCode` | string | No | `en-US` | Language for TTS output |
| `systemPrompt` | string | No | `"You are a helpful AI assistant. Provide clear, concise, and accurate responses."` | Custom system prompt for Mistral AI |

**Server responds with:** `aiResponse`, then `ttsAudio` (or `ttsError`)

---

### 4. `textMessage` — Send Text Instead of Voice

Use this to send a text message directly (no voice needed). Good for testing.

```javascript
socket.emit('textMessage', {
    message: 'What is machine learning?',     // required
    systemPrompt: 'You are a CS tutor.',      // optional
    languageCode: 'en-US'                     // optional
});
```

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `message` | string | **Yes** | — | The text message to send |
| `systemPrompt` | string | No | `"You are a helpful AI assistant."` | Custom system prompt |
| `languageCode` | string | No | `en-US` | Language for TTS output |

**Server responds with:** `aiResponse`, then `ttsAudio` (or `ttsError`)

---

### 5. `clearHistory` — Clear Chat History

Clears the Mistral AI conversation history for this session.

```javascript
socket.emit('clearHistory');
```

No payload. **Server responds with:** `historyCleared`

---

## Server to Client Events

### 1. `connected` — Welcome Message

Sent immediately when a client connects.

```json
{
    "message": "Connected to Speech-to-Text AI Server",
    "sessionId": "CXpNZ5mRdFiVwCpCAAAD"
}
```

---

### 2. `streamStarted` — STT Stream Ready

Sent after `startStream` is processed successfully.

```json
{
    "message": "Live streaming started"
}
```

---

### 3. `transcription` — Real-Time Speech Transcription

Sent multiple times while audio is streaming. Interim results update in real-time, final results are confirmed text.

```json
// Interim (partial, may change)
{
    "text": "What's going",
    "isFinal": false
}

// Final (confirmed, won't change)
{
    "text": "What's going on?",
    "isFinal": true
}
```

| Field | Type | Description |
|-------|------|-------------|
| `text` | string | Transcribed text |
| `isFinal` | boolean | `false` = interim (may change), `true` = final (confirmed) |

---

### 4. `aiResponse` — Mistral AI Text Response

Sent after stopStream/textMessage. Contains the AI's text reply.

```json
{
    "transcription": "What's going on?",
    "response": "Hello! I'm here and ready to assist you. How can I help you today?"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `transcription` | string | The user's original text (what was said/typed) |
| `response` | string | Mistral AI's text response |

---

### 5. `ttsAudio` — AI Voice Audio Response

Sent after `aiResponse`. Contains base64-encoded audio of the AI speaking its response.

```json
{
    "audioBase64": "UklGRi4AAABXQVZFZm10IBAAAA...",
    "mimeType": "audio/wav",
    "voice": {
        "name": "Vindemiatrix",
        "languageCode": "en-US"
    },
    "provider": "gemini-2.5-flash-preview-tts"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `audioBase64` | string | Base64-encoded audio data |
| `mimeType` | string | `audio/wav` (Gemini) or `audio/mpeg` (Google Cloud fallback) |
| `voice.name` | string | Voice used — `Vindemiatrix` (Gemini) or `en-US-Wavenet-F` (fallback) |
| `voice.languageCode` | string | Language of the audio |
| `provider` | string | Which TTS engine was used |

**How to play it on the client:**

```javascript
socket.on('ttsAudio', (data) => {
    const audioSrc = `data:${data.mimeType};base64,${data.audioBase64}`;
    const audio = new Audio(audioSrc);
    audio.play();
});
```

---

### 6. `ttsError` — TTS Failed

Sent if both Gemini TTS and Google Cloud TTS fail.

```json
{
    "message": "Failed to generate speech audio"
}
```

---

### 7. `historyCleared` — Chat History Cleared

Sent after `clearHistory`.

```json
{
    "message": "Chat history cleared"
}
```

---

### 8. `error` — Generic Error

Sent when something goes wrong.

```json
{
    "message": "Speech recognition error: ..."
}
```

---

## Full Request/Response Flow

### Voice Flow (Complete Lifecycle)

```
CLIENT                              SERVER
  │                                    │
  │──── connect ──────────────────────►│
  │◄─── connected {sessionId} ────────│
  │                                    │
  │──── startStream {config} ─────────►│  → Creates Google STT stream
  │◄─── streamStarted ───────────────│
  │                                    │
  │──── audioData (PCM buffer) ──────►│  → Pipes to Google STT
  │◄─── transcription {isFinal:false} │  ← Interim result
  │──── audioData (PCM buffer) ──────►│
  │◄─── transcription {isFinal:false} │  ← Updated interim
  │──── audioData (PCM buffer) ──────►│
  │◄─── transcription {isFinal:true} ─│  ← Final confirmed text
  │                                    │
  │  [silence detected → auto-stop]    │
  │                                    │
  │──── stopStream {config} ──────────►│  → Ends STT stream
  │                                    │  → Sends transcript to Mistral AI
  │◄─── aiResponse {text} ───────────│  ← AI text response
  │                                    │  → Converts response to speech
  │◄─── ttsAudio {audioBase64} ──────│  ← Audio of AI speaking
  │                                    │
  │  [browser plays audio]             │
  │                                    │
```

### Text Flow (No Voice Input)

```
CLIENT                              SERVER
  │                                    │
  │──── textMessage {message} ────────►│  → Sends to Mistral AI
  │◄─── aiResponse {text} ───────────│  ← AI text response
  │◄─── ttsAudio {audioBase64} ──────│  ← Audio of AI speaking
  │                                    │
```

---

## Audio Pipeline Details

### Client-Side Audio Capture

```javascript
// 1. Get microphone
const stream = await navigator.mediaDevices.getUserMedia({
    audio: { channelCount: 1, sampleRate: 16000 }
});

// 2. Create AudioContext at 16kHz
const audioContext = new AudioContext({ sampleRate: 16000 });

// 3. Chain: Mic → Analyser (volume) → ScriptProcessor (capture) → Destination
const microphone = audioContext.createMediaStreamSource(stream);
const analyser = audioContext.createAnalyser();
const processor = audioContext.createScriptProcessor(4096, 1, 1);

microphone.connect(analyser);
analyser.connect(processor);
processor.connect(audioContext.destination);

// 4. In processor callback — convert Float32 → Int16 and send
processor.onaudioprocess = (e) => {
    const float32 = e.inputBuffer.getChannelData(0);
    const int16 = new Int16Array(float32.length);
    for (let i = 0; i < float32.length; i++) {
        const s = Math.max(-1, Math.min(1, float32[i]));
        int16[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
    }
    socket.emit('audioData', int16.buffer);
};
```

### Audio Format Specs

| Property | Value |
|----------|-------|
| Encoding | LINEAR16 (raw PCM, 16-bit signed little-endian) |
| Sample Rate | 16,000 Hz |
| Channels | 1 (mono) |
| Bit Depth | 16 bits |
| Buffer Size | 4096 samples per chunk |
| Bytes per chunk | 8,192 bytes (4096 × 2 bytes) |

---

## TTS Configuration

### TTS Priority Chain

> **⚠️ Known Issue:** Gemini TTS (`gemini-2.5-flash-preview-tts`) frequently returns **500 Internal Server Errors**. Google Cloud TTS is the reliable fallback. For the Mock Interview system, Gemini TTS is **disabled by default** (set `ENABLE_GEMINI_TTS=true` in `.env` to re-enable).

```
1. Gemini TTS (Vindemiatrix voice)     ← Primary (may fail with 500s)
   ├── Attempt 1
   └── Attempt 2 (retry on 500 errors, 1s delay)
2. Google Cloud TTS (Wavenet-F voice)  ← Fallback (reliable)
```

### Gemini TTS (Primary)

| Setting | Value |
|---------|-------|
| **Service File** | `services/geminiTTS.service.js` |
| **Model** | `gemini-2.5-flash-preview-tts` |
| **Voice** | `Vindemiatrix` |
| **Output Format** | Raw PCM → converted to WAV (with RIFF header) |
| **Output Sample Rate** | 24,000 Hz |
| **API Key** | `GEMINI_API_KEY` in `.env` |
| **Retry** | 1 retry on transient 500 errors |

**Gemini API Request Structure:**

```javascript
const model = client.getGenerativeModel({
    model: 'gemini-2.5-flash-preview-tts',
    generationConfig: {
        responseModalities: ['audio'],
        speechConfig: {
            voiceConfig: {
                prebuiltVoiceConfig: {
                    voiceName: 'Vindemiatrix'
                }
            }
        }
    }
});

const result = await model.generateContent({
    contents: [{
        role: 'user',
        parts: [{ text: 'Say the following text naturally: Hello!' }]
    }]
});
// Response: result.response.candidates[0].content.parts[0].inlineData.data (base64 PCM)
```

**PCM → WAV Conversion:**

Gemini returns raw PCM audio (audio/L16). Browsers can't play this, so the server converts it to WAV by prepending a 44-byte RIFF header before sending to client.

### Google Cloud TTS (Fallback)

| Setting | Value |
|---------|-------|
| **Service File** | `services/textToSpeech.service.js` |
| **Voice** | `en-US-Wavenet-F` (female) |
| **SSML Gender** | `FEMALE` |
| **Audio Encoding** | `MP3` |
| **Speaking Rate** | `1.0` |
| **Pitch** | `0.0` |
| **Credentials** | `tts-campus-service-account.json` |

### Available Gemini Voices

You can change the voice by setting `GEMINI_TTS_VOICE` in `.env`:

| Voice Name | Description |
|-----------|-------------|
| `Vindemiatrix` | Default — warm, natural female voice |
| `Aoede` | Bright female voice |
| `Charon` | Deep male voice |
| `Fenrir` | Energetic male voice |
| `Kore` | Gentle female voice |
| `Puck` | Playful voice |

---

## STT Configuration

### Google Cloud Speech-to-Text

| Setting | Value |
|---------|-------|
| **Service File** | `services/speechToText.service.js` |
| **Mode** | Streaming recognition (real-time) |
| **Encoding** | `LINEAR16` |
| **Sample Rate** | `16,000 Hz` |
| **Punctuation** | Auto-enabled |
| **Interim Results** | Enabled (real-time partial transcripts) |
| **Credentials** | `hackathon-fusionnova-300407dd1e18.json` |

### Streaming Recognition Config

```javascript
{
    encoding: 'LINEAR16',
    sampleRateHertz: 16000,
    languageCode: 'en-US',
    enableAutomaticPunctuation: true,
    interimResults: true           // gives partial results as you speak
}
```

---

## Silence Detection Settings

Configured on the **client side** (browser). Automatically stops recording when user goes silent.

| Setting | Value | Description |
|---------|-------|-------------|
| `SILENCE_THRESHOLD` | `0.01` | RMS volume below this = silence |
| `SILENCE_DURATION` | `2000` ms | 2 seconds of silence triggers auto-stop |
| `MIN_SPEECH_DURATION` | `1000` ms | Must speak for at least 1 second before auto-stop is allowed |

### How It Works

```
1. AnalyserNode feeds RMS volume values
2. rms > 0.01  →  "speech detected", reset silence timer
3. rms ≤ 0.01  →  "silence", start 2-second countdown
4. If user spoke for >1s and silence lasts >2s → auto-call stopRecording()
5. stopRecording() emits 'stopStream' → triggers AI response
```

User can also click "Stop Manually" to force-stop at any time.

---

## Frontend Integration Code

### Minimal Working Example

```html
<!DOCTYPE html>
<html>
<head>
    <script src="/socket.io/socket.io.js"></script>
</head>
<body>
    <button id="start">Start</button>
    <button id="stop" disabled>Stop</button>
    <div id="output"></div>
    <audio id="player" controls></audio>

    <script>
        const socket = io();
        let audioContext, processor, microphone;

        // Listen for events
        socket.on('transcription', (data) => {
            document.getElementById('output').innerText =
                (data.isFinal ? '✅ ' : '🎤 ') + data.text;
        });

        socket.on('aiResponse', (data) => {
            document.getElementById('output').innerText = '🤖 ' + data.response;
        });

        socket.on('ttsAudio', (data) => {
            const player = document.getElementById('player');
            player.src = `data:${data.mimeType};base64,${data.audioBase64}`;
            player.play();
        });

        // Start recording
        document.getElementById('start').onclick = async () => {
            const stream = await navigator.mediaDevices.getUserMedia({
                audio: { channelCount: 1, sampleRate: 16000 }
            });

            audioContext = new AudioContext({ sampleRate: 16000 });
            microphone = audioContext.createMediaStreamSource(stream);
            processor = audioContext.createScriptProcessor(4096, 1, 1);

            processor.onaudioprocess = (e) => {
                const float32 = e.inputBuffer.getChannelData(0);
                const int16 = new Int16Array(float32.length);
                for (let i = 0; i < float32.length; i++) {
                    const s = Math.max(-1, Math.min(1, float32[i]));
                    int16[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
                }
                socket.emit('audioData', int16.buffer);
            };

            microphone.connect(processor);
            processor.connect(audioContext.destination);

            socket.emit('startStream', {
                encoding: 'LINEAR16',
                sampleRateHertz: 16000,
                languageCode: 'en-US'
            });

            document.getElementById('start').disabled = true;
            document.getElementById('stop').disabled = false;
        };

        // Stop recording
        document.getElementById('stop').onclick = () => {
            processor?.disconnect();
            microphone?.disconnect();
            audioContext?.close();

            socket.emit('stopStream', {
                languageCode: 'en-US',
                systemPrompt: 'You are a helpful assistant.'
            });

            document.getElementById('start').disabled = false;
            document.getElementById('stop').disabled = true;
        };
    </script>
</body>
</html>
```

### React/Next.js Integration

```javascript
import { useEffect, useRef, useState } from 'react';
import io from 'socket.io-client';

export function useVoiceChat(serverUrl = 'http://localhost:3000') {
    const socketRef = useRef(null);
    const audioContextRef = useRef(null);
    const [transcript, setTranscript] = useState('');
    const [aiResponse, setAiResponse] = useState('');
    const [isRecording, setIsRecording] = useState(false);

    useEffect(() => {
        socketRef.current = io(serverUrl);

        socketRef.current.on('transcription', (data) => {
            setTranscript(data.text);
        });

        socketRef.current.on('aiResponse', (data) => {
            setAiResponse(data.response);
        });

        socketRef.current.on('ttsAudio', (data) => {
            const audio = new Audio(`data:${data.mimeType};base64,${data.audioBase64}`);
            audio.play();
        });

        return () => socketRef.current?.disconnect();
    }, [serverUrl]);

    const startRecording = async () => {
        const stream = await navigator.mediaDevices.getUserMedia({
            audio: { channelCount: 1, sampleRate: 16000 }
        });

        audioContextRef.current = new AudioContext({ sampleRate: 16000 });
        const mic = audioContextRef.current.createMediaStreamSource(stream);
        const proc = audioContextRef.current.createScriptProcessor(4096, 1, 1);

        proc.onaudioprocess = (e) => {
            const f32 = e.inputBuffer.getChannelData(0);
            const i16 = new Int16Array(f32.length);
            for (let i = 0; i < f32.length; i++) {
                const s = Math.max(-1, Math.min(1, f32[i]));
                i16[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
            }
            socketRef.current.emit('audioData', i16.buffer);
        };

        mic.connect(proc);
        proc.connect(audioContextRef.current.destination);
        socketRef.current.emit('startStream', { encoding: 'LINEAR16', sampleRateHertz: 16000 });
        setIsRecording(true);
    };

    const stopRecording = () => {
        audioContextRef.current?.close();
        socketRef.current.emit('stopStream', {});
        setIsRecording(false);
    };

    return { transcript, aiResponse, isRecording, startRecording, stopRecording };
}
```

### Send Text Only (No Microphone)

```javascript
const socket = io('http://localhost:3000');

// Send text, get AI response + voice
socket.emit('textMessage', {
    message: 'Explain quantum computing in simple terms',
    systemPrompt: 'You are a physics teacher.',
    languageCode: 'en-US'
});

socket.on('aiResponse', (data) => {
    console.log('AI said:', data.response);
});

socket.on('ttsAudio', (data) => {
    // Play the audio
    const audio = new Audio(`data:${data.mimeType};base64,${data.audioBase64}`);
    audio.play();
});
```

---

## Supported Languages

Pass any of these as `languageCode` in `startStream` or `stopStream`:

| Code | Language |
|------|----------|
| `en-US` | English (US) — default |
| `en-GB` | English (UK) |
| `hi-IN` | Hindi |
| `es-ES` | Spanish |
| `fr-FR` | French |
| `de-DE` | German |
| `ja-JP` | Japanese |
| `zh-CN` | Chinese (Mandarin) |

---

## Error Handling

### All Possible Error Events

| Event | When | Payload |
|-------|------|---------|
| `error` | STT stream fails, audio processing fails, AI response fails | `{ message: "..." }` |
| `ttsError` | Both Gemini and Google Cloud TTS fail | `{ message: "Failed to generate speech audio" }` |

### Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Auto-play blocked` | Browser blocks audio without user interaction | User must click a button first, or enable auto-play in browser settings |
| `Speech recognition error` | Google STT stream timeout or invalid audio | Restart stream — streams timeout after ~60s of inactivity |
| `Failed to start recording` | Microphone permission denied | Grant mic access in browser |
| `Gemini TTS Error 500` | Transient Google server error | Auto-retries once; falls back to Google Cloud TTS |
| `Gemini TTS Error 403` | API key revoked/leaked | Generate new key at [AI Studio](https://aistudio.google.com/app/apikey), update `GEMINI_API_KEY` in `.env` |
| `Failed to synthesize speech` | Google Cloud TTS credentials invalid | Check `tts-campus-service-account.json` exists |

### Retry & Fallback Logic

```
Gemini TTS attempt 1
    ├── Success → return audio (WAV)
    └── Fail (500 only) → wait 1 second
        └── Gemini TTS attempt 2
            ├── Success → return audio (WAV)
            └── Fail → Google Cloud TTS fallback
                ├── Success → return audio (MP3)
                └── Fail → emit 'ttsError', return null
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `server.js` | Express + Socket.IO server setup |
| `sockets/voiceChat.socket.js` | All Socket.IO event handlers, TTS orchestration |
| `sockets/mockInterview.socket.js` | Mock Interview Socket.IO events (separate `/mock-interview` namespace) |
| `services/speechToText.service.js` | Google Cloud STT (streaming + batch) |
| `services/geminiTTS.service.js` | Gemini TTS with PCM→WAV conversion |
| `services/textToSpeech.service.js` | Google Cloud TTS fallback (Wavenet-F) |
| `services/mistralBot.service.js` | Mistral AI chat with history |
| `config/mistral.config.js` | Mistral model/temperature/maxTokens |
| `public/voice-chat.html` | Full frontend UI |
