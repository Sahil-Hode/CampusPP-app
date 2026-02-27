# Campus ++

Campus ++ is a Flutter-based academic companion app with AI-assisted features such as chatbot help, resume analysis, mock interview support, performance analytics, and learning-path guidance.

## Tech Stack

- Flutter (Dart) frontend
- Node.js + Express + Socket.IO backend (voice/chat utilities in `backend/`)
- Hosted API integration for authentication and core AI endpoints

## Project Structure

```text
campus-app/
├── lib/                  # Flutter application code
├── assets/               # Static assets and 3D models
├── backend/              # Node.js voice/chat backend
├── android/ ios/ web/    # Platform targets
└── README.md
```

## Prerequisites

- Flutter SDK
- Dart SDK compatible with the project (`^3.10.4`)
- Node.js 18+ and npm (for `backend/`)

## Frontend Setup

1. Install Flutter packages:

```bash
flutter pub get
```

2. Run the app:

```bash
flutter run
```

## Backend Setup (Optional for Local Voice Server)

1. Install dependencies:

```bash
cd backend
npm install
```

2. Create env file:

```bash
cp .env.example .env
```

3. Set required values in `.env`:

```env
PORT=3000
MISTRAL_API_KEY=...
ELEVENLABS_API_KEY=...
ELEVENLABS_VOICE_ID=...
GOOGLE_APPLICATION_CREDENTIALS=./google-credentials.json
```

4. Start backend:

```bash
npm run dev
```

Health check: `http://localhost:3000/health`

## Notes

- The Flutter app currently targets hosted endpoints like `https://campuspp-f7qx.onrender.com/api` for multiple features.
- `backend/` is useful for local voice/chat backend development and testing.
