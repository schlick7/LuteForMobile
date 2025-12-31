# Creating GitHub Releases for PWA Distribution

This guide explains how to create GitHub releases with the PWA zip file for users to download.

## Step 1: Build the PWA

Build the Flutter web app with correct base-href for local use:

```bash
flutter build web
```

**Note:** Do NOT use `--base-href` since this will be hosted locally.

## Step 2: Create Distribution ZIP

From the project root:

```bash
cd build/web
zip -r ../../lute-pwa.zip .
cd ../..
```

This creates `lute-pwa.zip` in your project root (~15MB).

## Step 3: Update Version Info

Optional: Update version in your app before building:

**web/manifest.json:**
```json
{
  "name": "LuteForMobile",
  "short_name": "Lute",
  "version": "1.0.0",
  ...
}
```

## Step 4: Create Git Tag

```bash
git add .
git commit -m "Release v1.0.0 - PWA distribution"

# Create and push tag
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

## Step 5: Create GitHub Release

### Via Web UI (Recommended)

1. Go to: https://github.com/schlick7/LuteForMobile/releases
2. Click "Create a new release"
3. Tag version: Select `v1.0.0`
4. Release title: `v1.0.0 - Local PWA Release`
5. Description:
   ```markdown
   ## LuteForMobile PWA - Local Distribution

   This release contains the PWA files for local hosting. Follow the setup guide:

   [PWA Setup Guide](https://github.com/schlick7/LuteForMobile/blob/main/PWA_SETUP_GUIDE.md)

   ### Features
   - Local HTTP hosting (no GitHub Pages needed)
   - Connects to local Lute server over HTTP
   - Works offline once cached
   - No expiration (unlike iOS sideloading)

   ### Installation
   1. Download `lute-pwa.zip`
   2. Extract to folder
   3. Run `python -m http.server 8000`
   4. Access from device: `http://YOUR_IP:8000`
   5. Add to home screen

   See [PWA Setup Guide](https://github.com/schlick7/LuteForMobile/blob/main/PWA_SETUP_GUIDE.md) for detailed instructions.
   ```
6. Attach files: Drag and drop `lute-pwa.zip`
7. Click "Publish release"

### Via GitHub CLI

```bash
# Install gh CLI if not installed: https://cli.github.com/

gh release create v1.0.0 \
  --title "v1.0.0 - Local PWA Release" \
  --notes "See PWA_SETUP_GUIDE.md for installation instructions" \
  lute-pwa.zip
```

## Step 6: Update Documentation

Add links to the release in your README or main page:

```markdown
## Download PWA

Latest release: [v1.0.0](https://github.com/schlick7/LuteForMobile/releases/latest)

[Download lute-pwa.zip](https://github.com/schlick7/LuteForMobile/releases/download/v1.0.0/lute-pwa.zip)

See [PWA Setup Guide](PWA_SETUP_GUIDE.md) for installation instructions.
```

## Version Bumping

For future releases:

### Semantic Versioning (MAJOR.MINOR.PATCH)
- **1.0.0** → **1.0.1**: Bug fix
- **1.0.0** → **1.1.0**: New feature
- **1.0.0** → **2.0.0**: Breaking changes

### Release Process

```bash
# 1. Update version in manifest.json
# 2. Make code changes
# 3. Build
flutter build web
cd build/web && zip -r ../../lute-pwa.zip . && cd ../..

# 4. Commit
git add .
git commit -m "Release v1.0.1 - Bug fixes"

# 5. Tag
git tag v1.0.1
git push origin main
git push origin v1.0.1

# 6. Create release via web or CLI
gh release create v1.0.1 \
  --title "v1.0.1 - Bug fixes" \
  lute-pwa.zip
```

## Multiple Downloads

If you want to offer multiple options:

### Option 1: PWA Only (Current)
- `lute-pwa.zip` (~15MB)
- Requires local HTTP server
- Connects to HTTP Lute server

### Option 2: Web Build for GitHub Pages
- Build with: `flutter build web --base-href /LuteForMobile/`
- Deployed to GitHub Pages
- Requires HTTPS Lute server or tunnel

### Option 3: Android APK
- Build with: `flutter build apk`
- ~20-30MB
- Connects to HTTP Lute server
- No server needed on user's device

## Changelog Maintenance

Keep a CHANGELOG.md in your repo:

```markdown
# Changelog

## [v1.0.0] - 2025-12-30
### Added
- Initial PWA release
- Local HTTP server hosting
- Support for local Lute server connections
- Offline capability with service worker

### Changed
- N/A

### Fixed
- N/A
```

Include this in release notes for each new version.

## Automated Release Workflow (Optional)

Create `.github/workflows/release.yml` for automated builds:

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - run: flutter build web

      - name: Create Zip
        run: |
          cd build/web
          zip -r ../../lute-pwa.zip .
          cd ../..

      - name: Release
        uses: softprops/action-gh-release@v1
        with:
          files: lute-pwa.zip
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This automatically:
- Triggers when you push a tag (v1.0.1, etc.)
- Builds the PWA
- Creates the zip
- Publishes GitHub release with attached zip

## Summary

The distribution flow is:

1. **You develop** → Code, test, commit to GitHub
2. **Build** → `flutter build web`, create zip
3. **Tag** → `git tag v1.0.0`, push
4. **Release** → GitHub release with attached zip
5. **Users download** → From GitHub Releases
6. **Users install** → Local HTTP server + add to home screen
7. **Users use** → Connect to local Lute server

No GitHub Pages hosting needed, no mixed content issues, works offline!
