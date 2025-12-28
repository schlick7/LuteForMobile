# LuteForMobile - Product Requirements Document

## 1. Overview

LuteForMobile is a mobile frontend application for the Lute v3 server, designed to provide a clean, uncluttered reading experience for language learners. The app focuses on facilitating reading comprehension through term management, translations, and AI-powered assistance.

### 1.1 Purpose
- Serve as a mobile client for the Lute v3 language learning server
- Provide an optimized reading experience on mobile devices
- Enable on-the-go language learning with accessible term lookup and translation tools

### 1.2 Target Audience
- Language learners using the Lute system
- Users who prefer mobile reading over desktop web browsers
- Learners who benefit from TTS and AI-assisted translation

---

## 2. Target Platforms

### 2.1 Primary Platform
- **Android** (primary testing device)

### 2.2 Secondary Platform
- **iOS** - Native Flutter app (or PWA as fallback)

---

## 3. Core Features

### 3.1 Reader

**Purpose:** Provide a clean, distraction-free reading environment

**Requirements:**
- Minimalist, uncluttered UI
- Main focus on text readability
- Double-tap gesture to open Term Form
- Tap gesture to open Translation popup

**Sub-features:**

#### Text Rendering
- Flutter RichText with TextSpan for interactive terms
- Tap gestures on specific words/terms
- Double-tap detection for Term Form
- Custom text selection handling

#### Term Form
- Triggered by double-tap
- Display term details from server
- Include Web Dictionary integration

#### Sentence Reader
- Text-to-Speech (TTS) functionality
- AI Translation support
- Sentence-level processing

#### Translation Popup
- Opens on tap (server-provided)
- Shows inline translation
- Non-intrusive display

#### Sentence Translation
- Integration with Web Dictionary (links from server)
- AI Translation support
- User-configurable translation source in settings

---

### 3.2 Books

**Purpose:** Manage and access reading materials

**Requirements:**
- Card-based UI design
- Display book metadata (title, language, progress)
- Easy navigation between books

---

### 3.3 Terms

**Purpose:** View and manage learned vocabulary

**Requirements:**
- List view of terms
- Search/filter functionality
- Term details view

---

### 3.4 Statistics

**Purpose:** Track learning progress and metrics

**Requirements:**
- Dashboard of learning metrics
- Charts/graphs for progress visualization
- Reading time tracking
- Vocabulary count tracking

---

### 3.5 Settings

#### 3.5.1 App Settings

**Server Configuration**
- Server URL input
- Connection testing

**AI Setup**
- Provider selector (Local, OpenAI, future providers)
- API key management
- Model selection (auto-fetch from Local endpoints)
- Custom prompts for word translation
- Custom prompts for sentence translation

**TTS Setup**
- TTS provider selection (KokoroTTS, NativeTTS)
- Voice selection
- Speed/pitch controls

**Theme**
- Light/Dark mode toggle
- Additional theme options (future)

#### 3.5.2 Lute Server Settings

- Full configuration options mirroring webview/endpoint
- Real-time synchronization with server settings

---

## 4. Technical Architecture

### 4.0 Flutter Architecture Pattern
- **Feature-first folder structure** (reader, books, terms, settings, etc.)
- **Separation of concerns**: UI widgets, business logic, data repositories
- **Dependency injection** using get_it or similar
- **Single source of truth** with state management

### 4.1 Network Layer
- **Centralized network calls** - Single module for all API communication
- Dio/HTTP client with interceptors for logging and error handling
- Consistent error handling and user feedback
- Request/response logging for debugging
- Offline support (future with Hive/sqflite)
- RESTful API integration with Lute v3 server

### 4.1.1 State Management
- Provider/Riverpod for global app state
- Local state with StatefulWidget for UI components
- BLoC pattern for complex business logic (optional)

### 4.2 AI Connectivity

**Providers:**
1. **Local (OpenAI-compatible)**
   - Auto-fetch available models
   - Custom prompts support
   - Word and sentence translation

2. **OpenAI**
   - API integration
   - Word translation prompts
   - Sentence translation prompts

3. **Future Providers** (extensible architecture)

### 4.3 TTS Manager

**Providers:**
- **KokoroTTS** - Primary option (HTTP API integration)
- **NativeTTS** - Fallback/alternative (using flutter_tts for native device TTS)
- **Google TTS** - Optional cloud-based TTS

**Features:**
- Voice selection and preview
- Playback controls (play, pause, stop)
- Speed and pitch adjustment
- Sentence-level playback highlighting
- Audio caching for offline playback

---

## 5. User Interface Requirements

### 5.1 Design Principles
- Clean, minimalist aesthetic using Flutter's Material Design
- Large touch targets for mobile (Material guidelines)
- High readability (appropriate font sizes, contrast)
- Consistent spacing and padding using Flutter theming
- Custom widgets for Reader UI (TextSpan for interactive terms)

### 5.2 Navigation
- Bottom navigation bar for main sections
- Back navigation for nested screens
- Gesture support (swipe, tap, double-tap)

### 5.3 Responsive Design
- Adaptable to different screen sizes
- Portrait-optimized (mobile-first)

---

## 6. Technical Specifications

### 6.1 Development Framework
- **Flutter** - Cross-platform framework using Dart
  - Native performance on both Android and iOS
  - Flutter Web for PWA option
  - Hot reload for fast development
  - Built-in widget library

### 6.2 Test Environment
- **Server:** 192.168.1.100:5001
- **Primary Test Device:** Android

### 6.3 PWA Requirements (for iOS - optional)
- Flutter Web build for PWA deployment
- Web manifest configuration
- Service worker for offline capability
- Responsive viewport settings
- Apple-specific meta tags

### 6.4 Flutter Requirements and Dependencies

#### Flutter Version Summary
| Component | Version | Status |
|-----------|---------|--------|
| Flutter | 3.38+ (stable) | ✅ Latest stable (Nov 12, 2025) |
| Dart | 3.10+ | ✅ Latest compatible |
| Android minSdk | 24 (Android 7.0) | ✅ Modern APIs |
| iOS minVersion | 12.0+ | ✅ Compatible |

**Note**: All packages listed below are fully compatible with Flutter 3.38+ and Dart 3.10

#### Core Flutter Packages
- `dio: ^5.9.0` - HTTP client for API calls with interceptors
- `flutter_riverpod: ^3.0.3` - State management (replaces provider)
- `shared_preferences: ^2.2.3` - Local data persistence (settings, server URL)
- `go_router: ^17.0.1` - Navigation and routing
- `get_it: ^9.2.0` - Dependency injection

#### UI/UX Packages
- `cached_network_image: ^3.3.1` - Image caching for book covers
- `shimmer` - Loading placeholders (verify compatibility)
- `flutter_markdown` - Markdown rendering for text content (verify compatibility)

#### Reader-Specific Packages
- `flutter_tts: ^4.0.2` - Text-to-Speech (NativeTTS)
- `speech_to_text` - Speech input (if needed for future features, verify compatibility)

#### AI Integration
- `openai_dart: ^0.6.2` - OpenAI API integration (recommended, latest version)
- Alternative: Custom HTTP client with dio for more control

#### Charts/Statistics
- `fl_chart: ^1.1.1` - Charts and graphs for statistics

#### Storage & Database
- `hive_ce: ^2.15.1` - Local database for offline support (books, terms) - Actively maintained community edition
- `hive_ce_flutter: ^2.3.2` - Flutter extensions for hive_ce
- Note: Use hive_ce instead of original hive (last updated 3 years ago)

#### Network & Utilities
- `connectivity_plus: ^6.0.3` - Network connectivity monitoring
- `dio_cache_interceptor` - HTTP response caching (verify compatibility with dio 5.9.0)
- `url_launcher: ^6.3.1` - Opening web dictionary URLs
- `flutter_inappwebview: ^6.1.5` - Web dictionary integration

#### PWA/Web (if using Flutter Web for iOS)
- `universal_html` - HTML5 API support
- `js` - JavaScript interop for PWA features

#### Development Tools
- `flutter_lints` - Dart linting rules
- `mocktail` - Testing mocks (recommended for Dart 3+)
- `integration_test` - Flutter integration testing
- `build_runner` - Code generation (if using freezed/json_serializable)

#### Package Compatibility Notes
- All packages above are compatible with Dart 3.10 and Flutter 3.38+
- Packages marked with "verify compatibility" should be checked during setup
- Dart SDK 3.10+ is required for all packages
- Always check pub.dev for latest versions and compatibility before adding packages

#### Package Compatibility Summary

| Package | Latest Version | Min Dart SDK | Status |
|---------|---------------|--------------|--------|
| flutter_riverpod | 3.0.3 | 3.7 | ✅ Compatible |
| riverpod | 3.0.3 | - | ✅ Compatible |
| dio | 5.9.0 | 2.18 | ✅ Compatible |
| flutter_tts | 4.0.2 | 2.15 | ✅ Compatible |
| go_router | 17.0.1 | - | ✅ Compatible |
| cached_network_image | 3.3.1 | 3.0 | ✅ Compatible |
| fl_chart | 1.1.1 | - | ✅ Compatible |
| hive_ce | 2.15.1 | 3.4 | ✅ Compatible (actively maintained) |
| hive_ce_flutter | 2.3.2 | - | ✅ Compatible |
| shared_preferences | 2.2.3 | 3.1 | ✅ Compatible |
| url_launcher | 6.3.1 | 3.3 | ✅ Compatible |
| connectivity_plus | 6.0.3 | 3.2 | ✅ Compatible |
| flutter_inappwebview | 6.1.5 | 3.5 | ✅ Compatible |
| get_it | 9.2.0 | 3.0 | ✅ Compatible |
| openai_dart | 0.6.2 | 3.8 | ✅ Compatible |

#### Minimum Flutter Version
- **Flutter**: 3.38+ (stable)
- **Dart**: 3.10+

#### Platform-Specific Requirements
- **Android**: minSdkVersion 24 (Android 7.0) - Better Flutter support and modern APIs
- **iOS**: iOS 12.0+
- **Permissions**:
  - Internet (required)
  - Storage (for offline caching)
  - Notification (if adding push notifications later)

#### Project Structure
```
lib/
├── main.dart
├── app.dart (App widget and routing)
├── config/ (app configuration, constants)
├── core/ (shared utilities, themes)
│   ├── network/ (API client, interceptors)
│   ├── storage/ (local storage, hive_ce)
│   └── theme/ (app theming)
├── features/
│   ├── reader/ (reader screens and widgets)
│   │   ├── models/
│   │   ├── providers/
│   │   ├── repositories/
│   │   └── widgets/
│   ├── books/ (book management)
│   ├── terms/ (term management)
│   ├── statistics/ (stats dashboard)
│   └── settings/ (app and server settings)
└── shared/ (shared widgets, components)
```

---

## 7. Success Metrics

- App stability (crash-free sessions)
- Fast loading times for books and terms
- Successful API call rate
- User engagement (reading time, term lookups)
- Positive user feedback on readability

---

## 8. Future Enhancements

- Offline mode for books and terms
- Anki integration for term export
- Cloud sync for settings
- Additional AI providers (Anthropic, Google, etc.)
- Social features (sharing progress)
- Gamification elements

---

## 9. Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| iOS PWA limitations | Flutter supports native iOS apps, eliminating most PWA constraints |
| Server connectivity issues | Implement robust error handling and offline queue |
| AI API rate limits | Implement request batching and caching |
| TTS provider availability | Support multiple TTS backends with graceful fallback |

---

## 10. Dependencies

### Backend
- Lute v3 server (backend)
- Stable network connection
