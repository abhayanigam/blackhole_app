# BlackHole Setup Guide

## Changes Made

This app has been updated with the following fixes and improvements:

### 1. Dependencies Fixed
- Added missing `http: ^1.1.0` package to pubspec.yaml
- Updated SDK constraint to support Flutter 3.x (`>=2.18.0 <4.0.0`)

### 2. RapidAPI Integration
The app now includes RapidAPI integration for Spotify and YouTube search functionality.

**API Configuration (`lib/APIs/rapidapi_config.dart`):**
- Spotify RapidAPI Key: `77f8752d1amsh5c0d547aa1ef8f8p12a92djsna0b6cc94f33b`
- YouTube RapidAPI Key: `77f8752d1amsh5c0d547aa1ef8f8p12a92djsna0b6cc94f33b`

**New Files Added:**
- `lib/APIs/rapidapi_config.dart` - RapidAPI configuration and headers
- `lib/APIs/youtube_rapidapi.dart` - YouTube RapidAPI service for searching

**Updated Files:**
- `lib/APIs/spotify_api.dart` - Added RapidAPI-based search methods (no OAuth required)
- `lib/Services/youtube_services.dart` - Added RapidAPI fallback for search suggestions

### 3. Android Configuration Updated
- Updated Gradle to 8.0 (`android/gradle/wrapper/gradle-wrapper.properties`)
- Updated Android Gradle plugin to 8.1.0 (`android/build.gradle`)
- Updated Kotlin version to 1.9.0
- Updated compileSdkVersion to 34
- Updated targetSdkVersion to 34
- Added namespace for AGP 8.0+ compatibility

### 4. iOS Configuration Updated
- Set minimum iOS platform to 12.0 (`ios/Podfile`)

## How to Run

### Prerequisites
1. Flutter SDK (3.0 or higher)
2. Android Studio or VS Code with Flutter extensions
3. For Android: Android SDK with API level 34
4. For iOS: Xcode 14+ and CocoaPods

### Steps to Run

```bash
# Navigate to the project directory
cd /app/BlackHole

# Get dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run on Android
flutter run -d android

# Run on iOS (macOS only)
flutter run -d ios

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### First Time Setup

1. **Clone and navigate:**
   ```bash
   cd BlackHole
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## API Keys Configuration

The RapidAPI keys are pre-configured in `lib/APIs/rapidapi_config.dart`. If you need to update them:

```dart
class RapidApiConfig {
  // Update these keys as needed
  static const String rapidApiKey = 'YOUR_RAPIDAPI_KEY';
  static const String spotifyHost = 'spotify81.p.rapidapi.com';
  static const String youtubeHost = 'youtube-data8.p.rapidapi.com';
}
```

## Features Enabled with RapidAPI

### Spotify (via RapidAPI)
- Track search
- Artist search  
- Album search
- Track details

### YouTube (via RapidAPI)
- Video search
- Search suggestions
- Video details
- Trending videos
- Playlist details

## Troubleshooting

### Common Issues

1. **Gradle sync fails:**
   - Make sure you have JDK 17 installed
   - Update Android Studio to the latest version

2. **iOS pod install fails:**
   - Run `cd ios && pod install --repo-update`

3. **API calls fail:**
   - Verify RapidAPI key is valid
   - Check your RapidAPI subscription status

4. **Build errors:**
   ```bash
   flutter clean
   flutter pub get
   flutter build
   ```

## Original App Info

- **App Name:** BlackHole
- **Package:** com.shadow.blackhole
- **Version:** 1.15.7+38

## License

This project is open source. See the LICENSE file for details.
