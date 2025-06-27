# EchoWave iOS App

This is the iOS client for the EchoWave feedback platform, built with SwiftUI.

## Project Structure

```
ios/
├── EchoWave.xcodeproj/     # Xcode project file
├── EchoWave/
│   ├── EchoWaveApp.swift   # App entry point
│   ├── ContentView.swift   # Root view with auth check
│   ├── Models/             # Data models
│   │   ├── User.swift
│   │   ├── Survey.swift
│   │   ├── Question.swift
│   │   ├── Response.swift
│   │   └── SurveySummary.swift
│   ├── Views/              # UI Views
│   │   ├── OnboardingView.swift
│   │   ├── AuthView.swift
│   │   ├── MainTabView.swift
│   │   ├── DashboardView.swift
│   │   ├── SurveysListView.swift
│   │   ├── CreateSurveyView.swift
│   │   ├── InsightsView.swift
│   │   └── ProfileView.swift
│   ├── ViewModels/         # View models (MVVM)
│   ├── Services/           # Business logic & API
│   │   ├── AuthManager.swift
│   │   └── NetworkManager.swift
│   ├── Utilities/          # Helper classes
│   │   └── KeychainManager.swift
│   ├── Extensions/         # Swift extensions
│   └── Resources/          # Assets, fonts, etc.
│       └── Assets.xcassets/
└── README.md
```

## Features Implemented

### Core Architecture
- ✅ MVVM architecture with SwiftUI
- ✅ Environment objects for state management
- ✅ Secure token storage with Keychain
- ✅ Network layer setup for API calls

### Authentication
- ✅ Sign in/Sign up views
- ✅ Form validation
- ✅ Secure password fields
- ✅ Social auth UI (implementation pending)
- ✅ Persistent auth state

### UI/UX
- ✅ Beautiful onboarding flow
- ✅ Teal & navy color scheme
- ✅ Tab-based navigation
- ✅ Loading states
- ✅ Error handling with alerts

### Security Features
- ✅ Keychain integration for token storage
- ✅ Input validation
- ✅ Secure text fields

## Getting Started

1. **Open the project**
   ```bash
   cd ios
   open EchoWave.xcodeproj
   ```

2. **Select your target**
   - Choose your simulator or connected device
   - Ensure iOS 16.0+ is selected

3. **Build and Run**
   - Press Cmd+R or click the play button
   - The app will launch in the simulator/device

## Development Status

### ✅ Completed
- Project scaffolding
- Authentication flow with sign in/sign up
- Beautiful onboarding with privacy emphasis
- Complete survey creation flow
  - Template selection (5 types)
  - Dynamic question builder
  - 4 question types (text, multiple choice, rating, yes/no)
  - QR code generation
  - Share functionality
- Survey management
  - List view with filters
  - Search functionality
  - Detailed survey view
  - Response tracking
- Gamification system
  - User levels & XP
  - Streak tracking
  - Achievement badges
  - Progress visualization
  - Level-up animations
- Dashboard with rich analytics
- Tab-based navigation
- Consistent UI/UX with teal/navy branding
- Empty states and loading indicators
- Form validation throughout

### 🚧 In Progress
- [ ] Backend API integration
- [ ] Real-time data synchronization
- [ ] Survey response submission view

### 📋 TODO
- [ ] Implement actual API calls (currently mocked)
- [ ] OpenAI integration for insights
- [ ] Push notifications setup
- [ ] Deep linking for survey URLs
- [ ] Social authentication (Google, Facebook, Instagram)
- [ ] In-app purchases for Pro/Team tiers
- [ ] Offline mode with data sync
- [ ] Export functionality (PDF, CSV)
- [ ] Multi-language support
- [ ] Accessibility improvements
- [ ] App Store assets (icon, screenshots)
- [ ] Privacy policy & terms of service
- [ ] Analytics integration (Firebase/Mixpanel)
- [ ] Crash reporting (Crashlytics)
- [ ] A/B testing framework
- [ ] Widget for quick survey access
- [ ] Apple Watch companion app

### 🐛 Known Issues
- Mock data is hardcoded
- No persistence between app launches
- Share sheet shows placeholder URL
- Some navigation flows need polish

## Dependencies

Currently, the app uses only native iOS frameworks:
- SwiftUI
- Foundation
- Security (Keychain)

Future dependencies to add:
- [ ] Alamofire (networking)
- [ ] SwiftKeychainWrapper
- [ ] QRCode generator
- [ ] Lottie (animations)

## Backend Requirements

The app expects a backend API at `http://localhost:3000/api/v1` with the following endpoints:
- POST `/auth/signin`
- POST `/auth/signup`
- GET `/surveys`
- POST `/surveys`
- GET `/surveys/:id`
- POST `/surveys/:id/responses`
- GET `/surveys/:id/summary`

## Testing

To run the app in different environments:

1. **Simulator**: Select any iOS 16+ simulator
2. **Device**: Connect your iPhone and select it as the target
3. **TestFlight**: Archive and upload (requires Apple Developer account)

## Contributing

1. Create a feature branch
2. Make your changes
3. Test on multiple device sizes
4. Submit a pull request

## Notes

- The app uses mock data for authentication during development
- Backend integration is pending
- Social auth buttons are UI-only for now
- All sensitive data is stored in Keychain 