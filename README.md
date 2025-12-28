# LuteForMobile

A Flutter mobile application for the Lute v3 language learning server, providing a clean, distraction-free reading experience for language learners on the go.

## Overview

LuteForMobile is a mobile frontend client for the Lute v3 server. It enables language learners to read books, manage vocabulary, and track progress on mobile devices with an optimized reading experience.

**Key Features:**
- Clean, minimalist reader with interactive text
- Tap gestures for translation lookup
- Double-tap for term details
- Word status highlighting (known vs unknown)
- Settings management
- Offline-ready architecture

**Platforms:**
- Android (primary)
- iOS (planned)

---

## Quick Start

### Prerequisites

1. **Flutter SDK** (3.38+ stable)
   ```bash
   flutter --version
   ```

2. **Lute v3 Server** running
   - Default: `http://localhost:5001`
   - See [Lute v3 Repository](https://github.com/jzohrab/lute-v3)

3. **Android Studio / VS Code** with Flutter plugin

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd LuteForMobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure server URL:
   - Open the app and go to Settings
   - Enter your Lute server URL (e.g., `http://192.168.1.100:5001`)
   - Tap "Test Connection" to verify

4. Run the app:
   ```bash
   flutter run
   ```

### Demo Data

Lute v3 server comes with demo books. Use book ID `14` for testing:
- Spanish demo book: "Aladino y la lámpara maravillosa"

---

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── app.dart                   # App widget and routing
├── core/                      # Shared utilities
│   └── network/               # API client, HTML parser
│       ├── api_client.dart    # Dio-based HTTP client
│       └── html_parser.dart  # HTML parsing from Lute server
├── features/                  # Feature modules
│   ├── reader/                # Reading functionality
│   │   ├── models/            # TextItem, Paragraph, PageData
│   │   ├── providers/         # State management
│   │   ├── repositories/      # Data access
│   │   └── widgets/           # UI components
│   └── settings/              # Settings management
│       ├── models/            # Settings model
│       ├── providers/         # Settings state
│       └── widgets/           # Settings UI
└── shared/                    # Shared widgets
    └── widgets/               # Common UI components
```

---

## Core Features

### Reader (Phase 1 - Complete)

The reader provides a clean reading experience with:

- **Interactive Text**: Tap on words for translation lookup
- **Status Highlighting**: Known words shown differently from unknown
- **Word Metadata**: Each word has status, ID, and position
- **Page Navigation**: Navigate between book pages

**Data Models:**
- `TextItem` - Individual word or space with metadata
- `Paragraph` - Group of text items
- `PageData` - Complete page with book info

**API Integration:**
- Endpoint: `/read/start_reading/<bookid>/<pagenum>`
- Parses HTML with embedded data attributes
- Extracts text, status, and sentence structure

### Settings Menu (Phase 3 - Complete)

Configure app settings:

- **Server URL**: Lute v3 server address
- **Default Book**: Book to open on launch
- **Default Page**: Page to open on launch

**Data Models:**
- `Settings` - App configuration stored locally

---

## Architecture

### State Management

- **Provider/Riverpod** for global state
- **StatefulWidget** for local UI state
- **Immutable models** for data

### Network Layer

- **Dio** HTTP client with interceptors
- Centralized API calls in `ApiClient`
- HTML parsing for Lute server responses
- Error handling and logging

### Data Flow

```
User Action → UI Widget → Provider → Repository → ApiClient → Lute Server
                                                    ↓
                                              HTML Response
                                                    ↓
                                            HtmlParser
                                                    ↓
                                            Data Models
                                                    ↓
                                                UI
```

---

## Development

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Code Quality

```bash
# Run linter
flutter analyze

# Format code
dart format .
```

### Dependencies

See `pubspec.yaml` for full list. Key dependencies:

- `dio: ^5.9.0` - HTTP client
- `flutter_riverpod: ^3.0.3` - State management
- `html: ^0.15.4` - HTML parsing
- `shared_preferences: ^2.2.3` - Local storage
- `go_router: ^17.0.1` - Navigation

---

## Documentation

### API Documentation

- [API Usage Guide](./docs/api_usage.md) - How to use Lute v3 API
- [API Response Examples](./docs/api_response_examples.md) - Response samples
- [Data Models](./docs/data_models.md) - Data model documentation

### Project Documentation

- [Phase Plan](./phaseplan.md) - Development phases and roadmap
- [PRD](./PRD.md) - Product Requirements Document
- [Lute Endpoints](./luteendpoints.md) - Complete endpoint reference
- [HTML Analysis](./phase1_html_analysis.md) - Phase 1 technical analysis

---

## Current Status

### Completed (Phases 1-4)

- ✅ **Phase 1**: Basic Reader (MVP)
  - HTML parsing from Lute server
  - Text rendering with RichText/TextSpan
  - Word status highlighting
  - Page navigation

- ✅ **Phase 2**: API and Translation Layer
  - ApiClient with Dio
  - HtmlParser for Lute responses
  - Service layer for data access

- ✅ **Phase 3**: Settings Menu
  - Server URL configuration
  - Default book/page settings
  - Local settings persistence

- ✅ **Phase 4**: Basic Documentation
  - API usage guide
  - Data models documentation
  - Response examples
  - Project README

### In Progress / Planned

See [Phase Plan](./phaseplan.md) for complete roadmap.

---

## Contributing

### Development Guidelines

1. Follow existing code style
2. Use immutable models where possible
3. Write tests for new features
4. Update documentation
5. Keep commits atomic and descriptive

### Code Style

- Use `dart format` before committing
- Run `flutter analyze` to check issues
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to Lute server

**Solution:**
1. Verify server is running: `curl http://localhost:5001`
2. Check server URL in Settings
3. Ensure device and server are on same network
4. Try server IP instead of localhost: `http://192.168.1.100:5001`

### Build Issues

**Problem:** Gradle build errors on Android

**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Empty Content

**Problem:** Book shows no text or "..." placeholder

**Solution:**
- Use `/read/start_reading/<bookid>/<pagenum>` endpoint
- Ensure book has content in Lute server
- Verify book/page IDs are correct

---

## Testing Server Connection

Test your Lute server is working:

```bash
# Test server is running
curl http://localhost:5001

# Test reading endpoint
curl "http://localhost:5001/read/start_reading/14/1"

# Test books endpoint
curl "http://localhost:5001/book/datatables/active"
```

---

## License

This project uses the same license as Lute v3.

---

## Acknowledgments

- [Lute v3](https://github.com/jzohrab/lute-v3) - Language learning server
- [Flutter](https://flutter.dev) - Cross-platform framework
- [Dio](https://pub.dev/packages/dio) - HTTP client

---

## Support

For issues with:
- **LuteForMobile**: Open an issue in this repository
- **Lute v3 Server**: Visit [Lute v3 Repository](https://github.com/jzohrab/lute-v3)

---

## Roadmap

See [Phase Plan](./phaseplan.md) for detailed development roadmap.

**Upcoming Features:**
- Enhanced reader (term form, translation popup)
- TTS integration (KokoroTTS, NativeTTS)
- Books management
- Vocabulary management
- Statistics dashboard
- AI-powered translation
- Offline support
