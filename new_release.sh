#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.2.3"
  exit 1
fi

VERSION="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_OUT="LuteForMobile-v${VERSION}.apk"
PWA_OUT="LuteForMobilePWA-v${VERSION}.zip"

require_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo is required but not found."
    exit 1
  fi
}

echo "Release version: ${VERSION}"
echo "Project folder: ${ROOT_DIR}"
echo
echo "Reminder: update pubspec.yaml version before continuing."
read -r -p "Press Enter to continue..."

echo
echo "1) Cleaning build artifacts..."
flutter clean

echo
echo "2) Building Android APK..."
flutter build apk --release

if [[ ! -f "$APK_SRC" ]]; then
  echo "Error: APK not found at $APK_SRC"
  exit 1
fi
cp "$APK_SRC" "$APK_OUT"
echo "Created: $APK_OUT"

echo
echo "3) Building web app..."
flutter build web

if [[ ! -f "setup_pwa.py" ]]; then
  echo "Error: setup_pwa.py not found in project root"
  exit 1
fi
cp setup_pwa.py build/web/

echo
echo "4) Fixing build/web permissions..."
require_sudo
sudo find build/web -type f -exec chmod 644 {} \;
sudo find build/web -type d -exec chmod 755 {} \;
sudo chown -R "$USER:$USER" build/web

echo
echo "5) Creating PWA zip..."
(
  cd build/web
  require_sudo
  sudo zip -r "../../${PWA_OUT}" . -x "*.last_build_id"
)

echo
echo "Release artifacts created:"
echo "- ${ROOT_DIR}/${APK_OUT}"
echo "- ${ROOT_DIR}/${PWA_OUT}"
