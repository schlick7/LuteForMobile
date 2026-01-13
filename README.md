# LuteForMobile

A Flutter mobile frontend for Lute v3 language learning server. Read books and learn languages on your phone or tablet.

## Features

- **Book Management** - Browse, read, and manage your language learning books
- **Sentence Reader** - Sentence parsing with term status tracking and highlighting
- **Audio Playback** - Integrated audio player with bookmark support
- **Dictionary Integration** - Inline dictionary lookup for terms
- **Theme System** - Dark, Light, Black and White
- **PWA Support** - Install as a web app on any device
- **TTS Support** - ondevice, Kokoro, openai
- **AI Translation Support** - Local OpenAI Endpoint (Ollama, Llama.cpp, etc.), OpenAI

## Supported Server Features
- ✅ Reader View
- ✅ Books View
- ✅ Terms View
- ✅ Statistics View
- X  Adding Books
- X  Language Settings

## Platforms
Native:
- 📱 Android 

PWA: (they should work, but are only lightly tested)
- 📱 Android (PWA)
- 📱 iOS (PWA)
- 🌐 Web (PWA)

## Prerequisites

- [Lute v3](https://github.com/LuteOrg/lute-v3) server running on your network

## Installation

### Option 1: Native - Download Release (Recommended)

#### Android

Download the latest APK from the [Releases page](https://github.com/schlick7/LuteForMobile/releases) and install it on your device.

### Option 2: PWA - limited web dictionary support (all are considered embedded) This the same as the Lute Webpage, but without popup dictionary support. 

Supports all platforms (lightly tested on iOS and web)

#### Quick Setup (Download)

1. Download the latest PWA zip from the [Releases page](https://github.com/schlick7/LuteForMobile/releases)
2. Extract the zip file:

```bash
unzip LuteForMobilePWA-[version].zip -d LuteForMobilePWA/
cd LuteForMobilePWA

# Run the automated setup script
python3 setup_pwa.py
```
**Windows users:** Run with `python setup_pwa.py` instead. Requires Docker Desktop on Windows.

The script will auto-detect your Lute installation and deploy the files. 

Or manually copy to:

**Pip/Venv Installation:**
```
{your_venv_path}/lib/python{version}/site-packages/lute/static/
```

**Docker Installation:**
```
/lute/static/
```
or
```
/lute-data/web/
```

**Source Installation:**
```
{lute_source_path}/lute/static/
```

4. The files should be placed in a `luteformobile/` subdirectory

Resart the Lute Server

Access the PWA at: `http://YOUR_LUTE_IP:5001/static/luteformobile/index.html`


### Option 3: Build Native Apps

#### Android

If you prefer to build from source, clone the repo and use the setup script:

```bash
git clone https://github.com/schlick7/LuteForMobile.git
cd LuteForMobile
```


```bash
# Install dependencies
flutter pub get
```
```bash
# Build Web/PWA
flutter build web

# Install PWA to Lute Server (run from build/web)
python3 setup_pwa.y
```
```bash
# Build Android APK
flutter build apk
```
```bash
# Build iOS
flutter build ios
```

#### iOS - UNTESTED - For "security" reasons this will expire 7 days after install (if you have work arounds let me know)



For detailed setup instructions, see [docs/QUICK_START.md](docs/QUICK_START.md).

## Configuration

### Server Connection

1. Open the app
2. Navigate to **Settings** → **Server URL**
3. Enter your Lute v3 server URL (e.g., `http://192.168.1.100:5001/`)
4. Save Settings
5. Click **Test Connection** at anytime to verify

### Theme Settings

1. Go to **Settings** → **Theme**
2. Choose from available themes

## Development

### Getting Started

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run tests
flutter test

# Run with specific platform
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS
```



## API Integration

This app communicates with Lute v3 server endpoints. For API documentation, see [docs/luteendpoints.md](docs/luteendpoints.md).

### Key Endpoints Used

- `GET /` - Main index page
- `GET /read/<bookid>` - Reading interface
- `POST /read/start_reading/` - Start reading session
- `POST /book/datatables/active` - Book listings
- `POST /term/datatables` - Term management

## Troubleshooting

### Connection Issues

- Ensure your Lute server is running
- Check firewall settings allow network access
- Verify the server URL includes the trailing slash

### Build Issues

```bash
# Clean build cache
flutter clean

# Reinstall dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

## Documentation

- [Quick Start Guide](docs/QUICK_START.md)
- [PWA Setup Guide](docs/PWA_SETUP_GUIDE.md)
- [API Endpoints](docs/luteendpoints.md)
- [GitHub Release Guide](docs/GITHUB_RELEASE_GUIDE.md)

## License

This project is licensed under the MIT License.

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Programmed with LLMs
  - Thanks to opencode for free access to Big Pickle, GLM-4.7, and MiniMax M2.1
  - Thanks to Qwen Code for 2000 free requests
- Uses [Lute v3](https://github.com/LuteOrg/lute-v3) backend
- Icons from [CupertinoIcons](https://pub.dev/packages/cupertino_icons)
- Fonts from various open source projects (see font directories for licenses)

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/schlick7/LuteForMobile/issues) page.
