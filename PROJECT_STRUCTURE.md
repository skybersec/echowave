# EchoWave Project Structure

This repository contains all components of the EchoWave feedback platform.

## Directory Layout

```
anonymized_feedback/
├── README.txt           # Product vision & detailed specifications
├── PROJECT_STRUCTURE.md # This file
├── ios/                 # Native iOS app (SwiftUI)
│   ├── EchoWave/       # iOS source code
│   └── README.md       # iOS-specific documentation
├── android/            # Native Android app (Jetpack Compose) - TODO
├── backend/            # Node.js/Express API server - TODO
├── web/                # Respondent web forms - TODO
└── docs/               # Additional documentation - TODO
```

## Technology Stack

### Mobile Apps
- **iOS**: SwiftUI, Swift 5.0+, iOS 16+
- **Android**: Jetpack Compose, Kotlin (planned)

### Backend
- **API**: Node.js + Express
- **Database**: SQLite (dev) → PostgreSQL (prod)
- **AI**: OpenAI GPT-4 integration
- **Auth**: JWT tokens
- **Storage**: S3-compatible for assets

### Web
- **Respondent Forms**: React/Next.js (planned)
- **Marketing Site**: Next.js + Tailwind (planned)

## Development Workflow

1. **Backend First**: Start the API server locally
2. **iOS Development**: Open `ios/EchoWave.xcodeproj` in Xcode
3. **Android Development**: Open `android/` in Android Studio (when ready)
4. **Web Development**: Run Next.js dev server in `web/` (when ready)

## Key Features
- 📱 Mobile-first design
- 🔒 k=10 anonymity guarantee
- 🤖 AI-powered insights
- 🎮 Gamification elements
- 🔐 Enterprise-grade security

See `README.txt` for complete product specifications. 