# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Poetry Writer is a Flutter-based AI-powered poetry creation app that helps users write poems by selecting words and using AI to generate poetry templates. The app supports Google, Apple, and guest login systems and is currently in development with basic authentication testing functionality.

## Development Commands

### Core Flutter Commands
- **Install dependencies**: `flutter pub get`
- **Run app**: `flutter run`
- **Build for release**: `flutter build apk` (Android) or `flutter build ios` (iOS)
- **Clean project**: `flutter clean`
- **Check environment**: `flutter doctor`

### Testing & Quality
- **Run tests**: `flutter test`
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format .`

### Firebase Configuration
The app uses Firebase for remote config and analytics. Firebase configuration files are located in:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## Architecture

### Core Principles
- **SOLID principles** with Clean Architecture
- **Interface-based design** with adapter pattern for services
- **Riverpod** for state management using Provider pattern
- **Mock implementations** for development and testing

### Project Structure
```
lib/
├── models/                 # Domain models (Word, Poetry, PoetryTemplate, UserInfo)
├── services/
│   ├── interfaces/        # Abstract interfaces for all services
│   └── implementations/   # Concrete implementations (Mock and real)
├── providers/             # Riverpod state management
├── screens/               # UI screens including DevTestScreen for development
└── widgets/               # Reusable UI components
```

### Service Layer Architecture
All services follow interface-first design:
- **AuthAdapter**: Google, Apple, Guest authentication with `AuthResult` response pattern
- **RemoteConfigAdapter**: Firebase Remote Config management
- **MessagingAdapter**: Firebase messaging (placeholder)
- **ApiService**: Backend API communication
- **StorageService**: Local data persistence
- **PoetryService** & **WordService**: Core business logic

### State Management
- Uses **flutter_riverpod** with Provider pattern
- Services are provided as singletons through providers
- State is managed through StateNotifier pattern for complex states

### Development Testing
The `DevTestScreen` (`lib/screens/dev_test_screen.dart`) provides a tabbed interface for testing:
- **Auth Tab**: Test Google, Apple, and Guest authentication
- **Remote Config Tab**: Test Firebase Remote Config
- **Messaging Tab**: Placeholder for Firebase messaging
- **Supabase Tab**: Test Supabase integration

## Key Dependencies

### Core Framework
- `flutter_riverpod: ^2.6.1` - State management
- `supabase_flutter: ^2.10.0` - Backend services

### Firebase Services
- `firebase_core: ^4.0.0`
- `firebase_remote_config: ^6.0.0`
- `firebase_analytics: ^12.0.0`
- `firebase_messaging: ^16.0.0`

### Storage & Data
- `shared_preferences: ^2.5.3` - Local settings
- `drift: ^2.28.1` - Local database (planned)

### Utilities
- `http: ^1.5.0` - HTTP client
- `package_info_plus: ^8.3.1` - App info
- `permission_handler: ^12.0.1` - Permissions

## Development Notes

### Authentication Testing
Use the DevTestScreen to test authentication flows:
1. Navigate to the Auth tab
2. Select provider (Google/Apple/Guest)
3. Initialize the adapter first
4. Test sign in/out functionality
5. Check logs in the integrated log viewer

### Mock Services
All services have mock implementations for development:
- Located in `lib/services/implementations/mock_*.dart`
- Follow the same interface as real implementations
- Include realistic delays and responses for testing

### Package Name
Current Android package: Check `android/app/build.gradle.kts` for the latest package name configuration.

### Coding Style
- Uses Material 3 theming with `ColorScheme.fromSeed`
- Korean language support in UI text
- Consistent card-based UI with 12px border radius
- Elevated buttons with 8px border radius
- String concatenation uses `+` operator instead of interpolation