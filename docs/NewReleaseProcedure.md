
cd /home/cody/LuteForMobile
scripts/release_app.sh 1.2.3




# Project Folder
- cd ~/LuteForMobile/

# Update Version
- Update pubspec.yaml

# Clean Build
- Flutter clean

# Build android
- Flutter build apk
- rename to LuteForMobile-vX.X.X

# Build PWA

## Build the web app first
- flutter build web

## Add script
- cp setup_pwa.py build/web/

## Fix permissions
- sudo find build/web -type f -exec chmod 644 {} \;
- sudo find build/web -type d -exec chmod 755 {} \;
- sudo chown -R $USER:$USER build/web

## Create the zip
- cd build/web
- sudo zip -r ../../LuteForMobilePWA.zip * -x "*.last_build_id"
- rename to LuteForMobilePWA-vX.X.X.zip

# On-device lute-server release (optional, separate cadence)

Only needed when you want to publish a new lute-v3 server artifact,
e.g. when upstream LuteOrg/lute-v3 releases a new version.

    scripts/release_lute_server.sh 3.11.0

This will:
1. Build lute-server-android-arm64-v3.11.0.tar.gz
2. Update Settings.luteServerPinnedVersion in lib/features/settings/models/settings.dart
3. Publish a lute-server-v3.11.0 GitHub release with the tarball + sha256
