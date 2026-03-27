<![CDATA[# 🎓 Campus++ — AI-Powered Smart Campus Companion

<p align="center">
  <img src="assets/logo.jpeg" width="120" alt="Campus++ Logo"/>
</p>

<p align="center">
  <strong>An all-in-one AI-powered academic companion app built with Flutter</strong><br>
  Combining AR/VR immersive experiences, voice-driven AI mentorship, predictive analytics, gamification, and career readiness — all in a single mobile application.
</p>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [App Architecture](#app-architecture)
- [Complete Feature List](#complete-feature-list)
- [Pages Breakdown](#pages-breakdown)
- [Services & Backend Integrations](#services--backend-integrations)
- [Data Models](#data-models)
- [UI Components & Widgets](#ui-components--widgets)
- [Setup & Installation](#setup--installation)

---

## 🧠 Overview

**Campus++** is a next-generation mobile application designed to completely transform the student academic experience. It integrates cutting-edge AI, Augmented Reality, Virtual Reality, real-time voice interactions, and predictive intelligence into a single Flutter-based mobile app.

The app serves as a student's complete academic companion — from tracking performance and predicting risks, to practicing mock interviews with AI agents, exploring 3D educational models in AR, writing and executing code directly in-app, and generating career-ready PDF reports.

---

## 🛠 Tech Stack

### Frontend
| Technology | Purpose |
|---|---|
| **Flutter** (Dart) | Cross-platform mobile framework |
| **Google Fonts (Poppins, Inter)** | Premium typography |
| **fl_chart** | Interactive charts & data visualization |
| **model_viewer_plus** | 3D GLB/GLTF model rendering |
| **flutter_unity_widget_2** | Unity 3D engine integration for VR |
| **flutter_inappwebview** | Advanced WebView for embedded content |
| **camera** | Live camera access for AR features |
| **speech_to_text** | Voice input / STT |
| **audioplayers** | Audio playback for TTS responses |
| **flutter_tts** | Text-to-Speech engine |
| **socket_io_client** | Real-time WebSocket communication |
| **record** | Audio recording for interviews |
| **file_picker** | Document upload (PDF/DOCX) |
| **image_picker** | Photo upload for profile |
| **code_text_field / highlight** | Syntax-highlighted code editor |
| **flutter_markdown** | Markdown rendering for AI responses |
| **dotted_border** | Decorative UI elements |
| **printing / pdf** | PDF generation & printing |
| **provider** | State management |
| **firebase_core** | Firebase initialization |
| **firebase_messaging** | Push notifications (FCM) |
| **flutter_local_notifications** | Local notification system |
| **permission_handler** | Runtime permission management |
| **shared_preferences** | Local storage for auth tokens |
| **url_launcher** | External link handling |
| **android_intent_plus** | Android-specific intents |
| **googleapis_auth** | Google API authentication |

### Backend
| Technology | Purpose |
|---|---|
| **Node.js / Express** | REST API server |
| **Socket.IO** | Real-time bidirectional communication |
| **MongoDB** | Database |
| **OpenAI GPT-4o** | AI responses, vision analysis, quiz generation |
| **OpenAI GPT-4o Vision** | Camera image analysis for AR Q&A |
| **Google Cloud TTS** | Text-to-Speech audio generation |
| **Firebase Cloud Messaging** | Push notification delivery |

---

## 🏗 App Architecture

```
lib/
├── main.dart                          # App entry point, Firebase init, routing
├── models/                            # 9 data models
├── pages/                             # 26 full-screen pages
├── providers/                         # State management (NotificationProvider)
├── screens/                           # Notification list screen
├── services/                          # 17 backend service classes
├── utils/                             # Notification handler utilities
└── widgets/                           # 16 reusable UI components
```

---

## ✅ Complete Feature List

### 🔐 1. Authentication & User Management
- **Student Login** — Email/password-based authentication with JWT token management
- **GitHub OAuth Integration** — Link GitHub account for project syncing
- **Persistent Sessions** — Auto-login via SharedPreferences token storage
- **Firebase Authentication** — FCM token registration per device
- **Profile Photo Upload** — Pick and upload profile avatar images
- **Profile Editing** — Update name, email, class, course, institute details

### 📊 2. Performance Analytics & Tracking
- **Overall Score Dashboard** — Real-time composite performance score (0-100)
- **Attendance Tracking** — Visual attendance percentage with trend indicators
- **Internal Marks Analysis** — Subject-wise marks breakdown and visualization
- **LMS Engagement Metrics** — Learning Management System usage tracking
- **Performance Charts** — Interactive line/bar charts using fl_chart
- **Subject Marks Cards** — Individual subject performance cards with color-coded grades
- **Score Breakdown** — Granular test-by-test score decomposition

### 🤖 3. AI-Powered Predictive Intelligence
- **Risk Level Assessment** — Automated High/Medium/Low risk classification
- **Predictive Dashboard** — Real-time AI-generated stability scores and trend analysis
- **Academic Stability Score** — Composite metric factoring consistency and trajectory
- **Failure Risk Percentage** — Statistical probability of academic failure
- **Trend Analysis** — Performance trend over time (Improving/Declining/Stable)
- **"What-If" Impact Simulation** — Simulate how actions affect future outcomes
- **Smart Alerts** — Severity-based alert system (Critical/Warning/Info)
- **Risk Breakdown** — Primary weakness identification and factor analysis
- **Risk Popup Notifications** — In-app popups for immediate risk awareness

### 🎤 4. AI Mock Interview System
- **Voice-Powered Interviews** — Real-time STT-driven AI mock interviews
- **Dual AI Interviewer Agents** — "Miss Priya" and "Mr. Vikram" AI interviewers
- **Resume-Based Questioning** — Interview questions generated from uploaded resume
- **Resume Source Selection** — Choose between profile resume or upload new for session
- **Live Camera Feed** — Real-time user camera during interview (toggle on/off)
- **Live Transcript Panel** — Real-time scrolling transcript of conversation
- **AI Audio Responses** — TTS-generated audio responses from interviewers
- **Interview Feedback Report** — Detailed AI-generated feedback after each session
  - Strengths analysis
  - Areas for improvement
  - Question-by-question breakdown
  - Overall performance rating
- **WebSocket Streaming** — Real-time Socket.IO audio/text streaming
- **Audio Recording** — Record user's voice responses for backend processing
- **Meeting-Style UI** — Video conference layout with participant tiles
- **Active Speaker Detection** — Visual indicator for who is currently speaking

### 🌐 5. VR Interview Environment
- **Unity 3D Integration** — Full Unity engine embedded in Flutter via flutter_unity_widget_2
- **VR Classroom Scene** — Immersive 3D classroom environment for interview practice
- **IL2CPP Compiled Native Code** — High-performance native Unity rendering
- **Gyroscope Camera Control** — Device motion-based camera movement in VR

### 🧑‍🏫 6. 3D AI Mentor (Deepak)
- **3D Animated Avatar** — Full GLB model with idle and talking animations
- **Voice Conversation** — Speak to the mentor via microphone
- **Multi-Language Support** — English, Hindi, Marathi, and Rajasthani
- **Context-Aware Responses** — Mentor has access to student's real academic data
- **Real-Time TTS Audio** — AI-generated voice responses played back in real-time
- **Lip-Sync Animation** — Model switches to talking animation when speaking
- **Socket.IO Backend** — Low-latency WebSocket communication for instant responses
- **Conversational AI** — Natural, human-like conversation (not robotic)

### 📱 7. Augmented Reality (AR) Features
- **AR Model Viewer** — Browse and view 3D educational models
- **AR Camera Overlay** — 3D models overlaid on live camera feed
- **Camera Snapshot Mode** — Periodic background captures for stable AR display
- **Model Size Control** — Slider to resize 3D models in AR scene
- **AI-Powered Object Recognition (OpenAI GPT-4o Vision)** — Point camera at any object and ask questions about it
- **AR Q&A System** — Voice-driven Q&A while viewing AR models
- **3D Model Generation** — AI-generated 3D models via Meshy API
- **Multiple Model Categories** — Educational models organized by subject

### 📄 8. Resume Management & Analysis
- **Resume Upload** — PDF/DOCX document upload
- **Profile Resume Storage** — Persistent resume attached to student profile
- **AI Resume Analyzer** — LLM-powered resume analysis with:
  - ATS Score (0-100)
  - Keyword detection
  - Formatting feedback
  - Strengths & weaknesses
  - Missing skills identification
- **Resume Text Extraction** — View parsed resume text
- **Resume Analysis Results Page** — Detailed breakdown with visual scoring
- **Scanning Animation** — Premium loading animation during analysis

### 📚 9. AI Learning Paths
- **AI-Generated Curriculum** — Custom learning paths generated for any topic
- **Chapter-by-Chapter Roadmap** — Structured learning with numbered steps
- **Progress Tracking** — Visual completion percentage per learning path
- **Step Completion** — Mark individual steps as completed
- **Roadmap Completion Overlay** — Celebration animation on 100% completion
- **Badge Earning** — Earn badges upon completing learning paths

### 🧩 10. AI Quiz System
- **Dynamic Quiz Generation** — AI-generated quizzes tied to learning path topics
- **Multiple Choice Questions** — Standard MCQ format with options
- **Auto-Grading** — Instant scoring and correct answer reveal
- **Quiz Score Cards** — Visual score display with percentage
- **Quiz Overview** — Summary of all completed quizzes

### 💻 11. Integrated Code Runner (IDE)
- **In-App Code Editor** — Full code editor with syntax highlighting
- **Multi-Language Support** — Python, JavaScript, Dart, Java, C++, and more
- **Code Execution** — Compile and run code directly in the app
- **Output Console** — View program output and errors
- **Syntax Highlighting** — Language-specific code coloring
- **Code Templates** — Pre-loaded starter code for each language

### 🏆 12. Gamification System
- **XP (Experience Points)** — Earn XP for all academic activities
- **Level System** — Level up based on accumulated XP
- **XP Progress Bar** — Visual progress toward next level
- **Badge Gallery** — Collection of earned badges categorized by type
  - Academic badges
  - Consistency badges
  - Achievement badges
  - Special rarity badges (Common/Rare/Epic/Legendary)
- **Badge Detail View** — Tap badges to see full details and earn date
- **Recent XP Feed** — Activity log of recent XP-earning actions
- **Stats Grid** — Quick stats overview (Total XP, Level, Streak, Badges)
- **Leaderboard** — Ranking against other students
- **Streak Tracking** — Consecutive day engagement tracking
- **Celebration Overlay** — Animated celebration on badge earn

### 🔔 13. Push Notification System
- **Firebase Cloud Messaging (FCM)** — Remote push notifications
- **Local Notifications** — In-app notification generation
- **Notification Channels** — Categorized Android notification channels:
  - Critical Alerts (max priority)
  - Warning Alerts (high priority)
  - Information (default priority)
- **Notification Provider** — State management for unread notification count
- **Notification List Screen** — Full notification history with filtering
- **Notification Badge** — Unread count badge on dashboard
- **Notification Cards** — Rich notification cards with severity indicators
- **Background Message Handler** — Handle notifications when app is closed
- **Tap-to-Navigate** — Tapping notifications routes to relevant pages
- **Token Auto-Refresh** — Automatic FCM token refresh handling

### 👨‍🏫 14. Faculty Notes & Interventions
- **Faculty Annotations** — View notes and comments from faculty members
- **Intervention System** — AI-recommended intervention actions
- **Intervention Priority** — Prioritized action items for academic recovery
- **Tab-Based View** — Separate tabs for Notes and Interventions
- **Action Cards** — Individual intervention action items with status
- **Review Cards** — Faculty review summaries
- **Time-Ago Display** — Relative timestamps for notes

### 🤝 15. AI Council System
- **AI Decision Engine** — Multi-factor AI analysis for academic guidance
- **Council Dashboard** — Comprehensive AI-generated academic overview
- **Contextual Recommendations** — Data-driven personalized advice
- **Performance-Based Insights** — AI insights tied to real performance data

### 📊 16. Career Report Generator
- **Career Readiness Score** — AI-computed career preparedness metric
- **PDF Report Generation** — Professional PDF career report with:
  - Student profile header
  - Career readiness breakdown
  - Resume analysis summary
  - Learning progress overview
  - Project portfolio
  - Mock interview performance
  - Skills assessment
  - AI recommendations
- **PDF Preview & Print** — In-app PDF preview with print capability
- **Download Report** — One-tap career report generation from profile

### 🔗 17. GitHub & Project Integration
- **GitHub OAuth** — Authenticate with GitHub account
- **Repository Syncing** — Sync GitHub repositories to student profile
- **Project Detail View** — Detailed view of individual projects
- **Project Status Tracking** — Track project progress and completion

### 🎨 18. UI/UX Design System
- **Retro-Neobrutalist Design** — Bold borders, solid shadows, vibrant colors
- **Glassmorphic Elements** — Frosted glass panels with BackdropFilter
- **Google Fonts** — Poppins and Inter typography throughout
- **Dark Mode Support** — Dark-themed components where applicable
- **Micro-Animations** — Smooth transitions and hover effects
- **Responsive Layout** — Adaptive UI for different screen sizes
- **Custom Navigation Bar** — Bottom navigation with active state indicators
- **Loading Animations** — Analyzing animation, scanning animation, typing indicators
- **Celebration Overlays** — Confetti-style achievement celebrations

### 🛡 19. User Feedback System
- **In-App Feedback Dialog** — Contextual feedback prompts after using features
- **Feature-Specific Feedback** — Separate feedback for each major feature
- **Rating System** — Star-based feature rating
- **Feedback Submission** — Send feedback to backend for analysis

---

## 📄 Pages Breakdown (26 Pages)

| # | Page | File | Description |
|---|---|---|---|
| 1 | Landing Page | `landing_page.dart` | Animated intro/splash screen with feature highlights |
| 2 | Login Page | `login_page.dart` | Email/password authentication |
| 3 | GitHub OAuth Page | `github_oauth_page.dart` | GitHub account linking via OAuth |
| 4 | Dashboard Page | `dashboard_page.dart` | Central hub — stats, charts, quick actions, navigation |
| 5 | Profile Page | `profile_page.dart` | Student details, photo upload, resume, career report |
| 6 | Performance Analysis | `performance_analysis_page.dart` | Marks, attendance tables, charts |
| 7 | Predictive Dashboard | `predictive_dashboard_page.dart` | AI risk metrics, stability scores, what-if simulation |
| 8 | Score Breakdown | `score_breakdown_page.dart` | Granular test score decomposition |
| 9 | Interventions | `interventions_page.dart` | AI-recommended academic actions |
| 10 | AI Analysis | `ai_analysis_page.dart` | Contextual AI performance review |
| 11 | AI Council | `ai_council_page.dart` | Advanced AI decision-making guidance |
| 12 | Learning Path | `learning_path_page.dart` | Learning path listing & tracking |
| 13 | Learning Path Detail | `learning_path_detail_page.dart` | Individual path with module completion |
| 14 | Quiz Page | `quiz_page.dart` | AI-generated quizzes |
| 15 | Project Detail | `project_detail_page.dart` | GitHub repository/project view |
| 16 | Code Runner | `code_runner_page.dart` | In-app IDE with code execution |
| 17 | Resume Upload | `resume_upload_page.dart` | Document upload form |
| 18 | Resume Analysis Result | `resume_analysis_result_page.dart` | ATS scoring & analysis display |
| 19 | Mock Interview | `mock_interview_page.dart` | Voice AI interview with feedback |
| 20 | VR Interview | `vr_interview_page.dart` | Unity-powered VR interview environment |
| 21 | 3D Mentor | `three_d_mentor_page.dart` | Voice-interactive 3D AI mentor (Deepak) |
| 22 | AR Viewer | `ar_viewer_page.dart` | AR model browsing & viewing |
| 23 | AR Model Detail | `ar_model_detail_page.dart` | AR model controls & information |
| 24 | AR Camera Q&A | `ar_camera_qa_page.dart` | Camera + 3D model + voice Q&A with GPT-4o Vision |
| 25 | Gamification | `gamification_page.dart` | XP, badges, leaderboard, streaks |
| 26 | Faculty Notes | `faculty_notes_page.dart` | Faculty annotations & interventions |

---

## ⚙️ Services & Backend Integrations (17 Services)

| # | Service | File | Purpose |
|---|---|---|---|
| 1 | AI Service | `ai_service.dart` | Core AI API communication |
| 2 | AR Generation Service | `ar_generation_service.dart` | 3D model generation via Meshy API |
| 3 | Auth Service | `auth_service.dart` | JWT authentication & token management |
| 4 | Career Report PDF Generator | `career_report_pdf_generator.dart` | PDF career report generation |
| 5 | Career Report Service | `career_report_service.dart` | Career report data fetching |
| 6 | Code Runner Service | `code_runner_service.dart` | Remote code compilation & execution |
| 7 | Feedback Service | `feedback_service.dart` | User feedback submission |
| 8 | Gamification Service | `gamification_service.dart` | XP, badges, leaderboard APIs |
| 9 | Local Notification Service | `local_notification_service.dart` | Android/iOS local notifications |
| 10 | Mock Interview Service | `mock_interview_service.dart` | Mock interview REST APIs |
| 11 | Mock Interview Socket Service | `mock_interview_socket_service.dart` | Real-time Socket.IO for interviews |
| 12 | Notification Service | `notification_service.dart` | Push notification management |
| 13 | Project Service | `project_service.dart` | GitHub project syncing |
| 14 | Quiz Service | `quiz_service.dart` | AI quiz generation & grading |
| 15 | Resume Service | `resume_service.dart` | Resume upload & analysis |
| 16 | Student Service | `student_service.dart` | Core student data CRUD operations |
| 17 | Vision Service | `vision_service.dart` | OpenAI GPT-4o Vision for object recognition |

---

## 📦 Data Models (9 Models)

| # | Model | File | Purpose |
|---|---|---|---|
| 1 | Faculty Annotation | `faculty_annotation_model.dart` | Faculty notes/comments structure |
| 2 | Gamification | `gamification_model.dart` | XP, badges, leaderboard entries |
| 3 | Mock Interview | `mock_interview_model.dart` | Interview session & feedback data |
| 4 | Notification | `notification_model.dart` | Push notification payload structure |
| 5 | Performance | `performance_model.dart` | Academic performance metrics |
| 6 | Quiz | `quiz_model.dart` | Quiz questions, answers, scores |
| 7 | Resume Analysis | `resume_analysis_model.dart` | ATS score & analysis results |
| 8 | Student | `student_model.dart` | Core student data |
| 9 | Student Profile | `student_profile_model.dart` | Extended profile with metadata |

---

## 🧩 UI Components & Widgets (16 Widgets)

| # | Widget | File | Purpose |
|---|---|---|---|
| 1 | Analyzing Animation | `analyzing_animation.dart` | Pulsing/loading animation during AI analysis |
| 2 | Attendance Card | `attendance_card.dart` | Attendance percentage display card |
| 3 | Celebration Overlay | `celebration_overlay.dart` | Confetti animation for achievements |
| 4 | Feedback Dialog | `feedback_dialog.dart` | In-app feature feedback prompt |
| 5 | LMS Engagement Card | `lms_engagement_card.dart` | LMS usage statistics card |
| 6 | Notification Badge | `notification_badge.dart` | Unread notification count badge |
| 7 | Notification Card | `notification_card.dart` | Rich notification display card |
| 8 | Overall Score Card | `overall_score_card.dart` | Main performance score widget |
| 9 | Quiz Overview Card | `quiz_overview_card.dart` | Quiz summary card |
| 10 | Quiz Score Card | `quiz_score_card.dart` | Individual quiz score display |
| 11 | Roadmap Completion Overlay | `roadmap_completion_overlay.dart` | Learning path completion celebration |
| 12 | Scanning Animation | `scanning_animation.dart` | Resume/document scanning animation |
| 13 | Severity Indicator | `severity_indicator.dart` | Risk level color indicator |
| 14 | Status Card | `status_card.dart` | Generic status display card |
| 15 | Subject Marks Card | `subject_marks_card.dart` | Per-subject grade card |
| 16 | Typing Indicator | `typing_indicator.dart` | AI is typing... animation |

---

## 🚀 Setup & Installation

### Prerequisites
- Flutter SDK (3.38.5+)
- Android SDK (API 26+)
- Android NDK (27.0+)
- Unity Editor (6000.3.10f1) — for VR features
- Firebase project with `google-services.json`

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Sahil-Hode/CampusPP-app.git
cd CampusPP-app

# 2. Install dependencies
flutter pub get

# 3. Set up Firebase
# Place google-services.json in android/app/

# 4. Run the app
flutter run
```

### Build APK
```bash
flutter build apk --debug
```

---

## 📊 Project Stats

| Metric | Count |
|---|---|
| **Total Pages** | 26 |
| **Total Services** | 17 |
| **Total Data Models** | 9 |
| **Total Widgets** | 16 |
| **Total Dart Files** | 70+ |
| **Supported Languages** | English, Hindi, Marathi, Rajasthani |
| **AI Models Used** | OpenAI GPT-4o, GPT-4o Vision |
| **3D Engines** | model_viewer_plus, Unity 3D |

---

## 👥 Team

Built with ❤️ by the Campus++ Team

---

<p align="center">
  <sub>© 2026 Campus++ — All Rights Reserved</sub>
</p>
]]>
