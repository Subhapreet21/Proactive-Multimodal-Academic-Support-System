# Campus OS - Flutter Mobile App

A native mobile application version of Campus OS, an AI-powered university assistant built with Flutter.

## 📱 Features

All features from the web application have been ported to mobile:

- **🤖 AI Chat Assistant**: Text, voice, and image-based queries using Google Gemini
- **📅 Smart Timetable**: Role-based schedule management (Student/Faculty/Admin)
- **📢 Events & Notices**: Campus announcements and event board
- **✅ Task Management**: Personal reminders with category tagging
- **📚 Knowledge Base**: University handbook search
- **👤 User Profiles**: Role-based access control with onboarding
- **🎨 Modern UI**: Dark theme with smooth animations

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode (for iOS)
- Android device/emulator or iOS device/simulator

### Installation

1. **Install Flutter**:
   Follow the official Flutter installation guide: https://flutter.dev/docs/get-started/install

2. **Navigate to the Flutter app directory**:
   ```bash
   cd flutter_app
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Configure environment variables**:
   Create a `.env` file in the `flutter_app` directory:
   ```env
   API_URL=http://10.0.2.2:8000          # For Android emulator
   # API_URL=http://YOUR_LOCAL_IP:8000  # For physical device
   CLERK_PUBLISHABLE_KEY=your_clerk_key
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

   > **Note**: For physical Android devices, replace `10.0.2.2` with your computer's local IP address.

5. **Ensure backend is running**:
   The Flutter app communicates with the existing Express backend. Make sure it's running:
   ```bash
   cd ../backend
   npm run dev
   ```

6. **Run the app**:
   ```bash
   flutter run
   ```

## 📱 Platform-Specific Setup

### Android

1. Enable USB debugging on your device
2. Connect device via USB or use an emulator
3. Run: `flutter run`

### iOS (macOS only)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing with your Apple Developer account
3. Run: `flutter run`

## 🏗️ Project Structure

```
flutter_app/
├── lib/
│   ├── config/          # App configuration (theme, routes, env)
│   ├── models/          # Data models
│   ├── providers/       # State management (Provider pattern)
│   ├── screens/         # All app screens
│   ├── services/        # API services
│   ├── utils/           # Utility functions
│   ├── widgets/         # Reusable UI components
│   └── main.dart        # App entry point
├── assets/              # Images and static files
├── pubspec.yaml         # Dependencies
└── .env.example         # Environment template
```

## 🔑 Authentication

The app uses a simplified authentication flow for demo purposes. In production, integrate with Clerk's official authentication:

1. Sign in with any email/name (mock authentication)
2. Complete onboarding by selecting your role:
   - **Student**: Select Department, Year, and Section
   - **Faculty/Admin**: Enter access code

## 📋 Key Dependencies

- **provider**: State management
- **go_router**: Navigation and routing
- **http**: API communication
- **flutter_secure_storage**: Secure token storage
- **image_picker**: Image selection for AI queries
- **speech_to_text**: Voice input
- **flutter_dotenv**: Environment variables
- **intl**: Date/time formatting

## 🔧 Troubleshooting

### Backend Connection Issues

**Problem**: "Network error" or connection refused

**Solutions**:
- Ensure backend is running on port 8000
- For Android emulator, use `http://10.0.2.2:8000`
- For physical device, use your computer's local IP (e.g., `http://192.168.1.100:8000`)
- Check firewall settings

### Build Errors

**Problem**: Package conflicts or build failures

**Solutions**:
```bash
flutter clean
flutter pub get
flutter run
```

### Speech Recognition Not Working

**Problem**: Voice input not available

**Solutions**:
- Grant microphone permissions in device settings
- Speech recognition requires internet connection
- Not all devices/emulators support speech recognition

## 🎨 Customization

### Theme

Edit `lib/config/theme.dart` to customize colors and styling:
```dart
static const Color primaryColor = Color(0xFF6366F1);
static const Color backgroundColor = Color(0xFF0F172A);
```

### API Endpoints

Modify `lib/utils/constants.dart` to update API routes:
```dart
static const String dashboardEndpoint = '/api/dashboard';
```

## 📝 Notes

- This is a feature-complete mobile version of Campus OS web app
- Backend API remains unchanged from the web version
- All authentication flows and data models match the web implementation
- Role-based access control is fully implemented

## 🤝 Contributing

This Flutter app is part of the Campus OS project. For issues or contributions related to:
- **Mobile UI/UX**: Submit issues with [Mobile] tag
- **Backend API**: Refer to main backend documentation
- **Features**: Both mobile and web should maintain feature parity

## 📄 License

Same license as the main Campus OS project.
