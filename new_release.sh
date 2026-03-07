#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

PUBSPEC_FILE="pubspec.yaml"
APK_SRC="build/app/outputs/flutter-apk/app-release.apk"

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is required but not found."
    exit 1
  fi
}

if [[ ! -f "$PUBSPEC_FILE" ]]; then
  echo "Error: ${PUBSPEC_FILE} not found in ${ROOT_DIR}"
  exit 1
fi

CURRENT_VERSION="$(awk '/^version:[[:space:]]*/ {print $2; exit}' "$PUBSPEC_FILE")"
if [[ -z "${CURRENT_VERSION}" ]]; then
  echo "Error: Could not parse current version from ${PUBSPEC_FILE}"
  exit 1
fi

CURRENT_DISPLAY_VERSION="${CURRENT_VERSION%%+*}"
if [[ "$CURRENT_VERSION" == *"+"* ]]; then
  CURRENT_BUILD_NUMBER="${CURRENT_VERSION##*+}"
else
  CURRENT_BUILD_NUMBER="0"
fi

if [[ $# -ge 1 ]]; then
  NEW_VERSION="$1"
else
  echo "=========================================="
  echo "Current Version: ${CURRENT_DISPLAY_VERSION} (Build ${CURRENT_BUILD_NUMBER})"
  echo "=========================================="
  read -r -p "Enter new version (e.g., 0.8.3) [${CURRENT_DISPLAY_VERSION}]: " NEW_VERSION
  NEW_VERSION="${NEW_VERSION:-$CURRENT_DISPLAY_VERSION}"
fi

if [[ -z "${NEW_VERSION}" ]]; then
  echo "Error: version cannot be empty"
  exit 1
fi

if [[ $# -ge 2 ]]; then
  NEW_BUILD_NUMBER="$2"
else
  DEFAULT_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
  read -r -p "Enter new build number [${DEFAULT_BUILD_NUMBER}]: " NEW_BUILD_NUMBER
  NEW_BUILD_NUMBER="${NEW_BUILD_NUMBER:-$DEFAULT_BUILD_NUMBER}"
fi

if [[ ! "$NEW_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "Error: build number must be numeric"
  exit 1
fi

FULL_VERSION="${NEW_VERSION}+${NEW_BUILD_NUMBER}"
APK_OUT="LuteForMobile-v${NEW_VERSION}.apk"
PWA_OUT="LuteForMobilePWA-v${NEW_VERSION}.zip"

echo "=========================================="
echo "Creating Release ${NEW_VERSION} (Build ${NEW_BUILD_NUMBER})"
echo "=========================================="
echo "Project folder: ${ROOT_DIR}"

sed -i "s/^version: .*/version: ${FULL_VERSION}/" "$PUBSPEC_FILE"
echo "Updated ${PUBSPEC_FILE} -> version: ${FULL_VERSION}"

echo
echo "1) Cleaning build artifacts..."
flutter clean

echo
echo "2) Getting dependencies..."
flutter pub get

echo
echo "3) Building Android APK..."
flutter build apk --release

if [[ ! -f "$APK_SRC" ]]; then
  echo "Error: APK not found at $APK_SRC"
  exit 1
fi
cp "$APK_SRC" "$APK_OUT"
echo "Created: $APK_OUT"

echo
echo "4) Building web app..."
flutter build web

if [[ ! -f "setup_pwa.py" ]]; then
  echo "Error: setup_pwa.py not found in project root"
  exit 1
fi
cp setup_pwa.py build/web/

echo
echo "5) Fixing build/web permissions..."
require_sudo
sudo find build/web -type f -exec chmod 644 {} \;
sudo find build/web -type d -exec chmod 755 {} \;
sudo chown -R "$USER:$USER" build/web

echo
echo "6) Creating PWA zip..."
(
  cd build/web
  require_sudo
  sudo zip -r "../../${PWA_OUT}" . -x "*.last_build_id"
)

echo
echo "=========================================="
echo "Release Complete"
echo "=========================================="
echo "Release artifacts created:"
echo "- ${ROOT_DIR}/${APK_OUT}"
echo "- ${ROOT_DIR}/${PWA_OUT}"
echo "Version: ${NEW_VERSION} (Build ${NEW_BUILD_NUMBER})"
echo
echo "Remember to commit the pubspec.yaml version bump."
