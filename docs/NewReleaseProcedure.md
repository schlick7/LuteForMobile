
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

# On-device lute-v3 server source update

The lute-v3 server is **bundled in the APK** (under
`android/app/src/main/python/lute/`), not released as a separate
artifact. There is no `scripts/release_lute_server.sh` step.

To bump the bundled server:

1. Follow the overlay procedure in `docs/on-device-server.md`:
   - Clone `https://github.com/schlick7/lute-v3` at branch `fullstats`.
   - `rsync` its `lute/` tree over `android/app/src/main/python/lute/`,
     excluding `bridge.py` and `db/language_defs/` (both are
     Android-specific and not in the fork).
   - Restore the three Android-specific patches listed in
     `docs/on-device-server.md` (bridge.py, app_factory.py,
     backup/service.py).
2. Bump `__version__` in
   `android/app/src/main/python/lute/__init__.py` to match the
   pinned version label.
3. Bump `luteServerPinnedVersion` in
   `lib/features/settings/models/settings.dart` to the same label.
4. Then run `scripts/release_app.sh <app-version>` to ship the APK +
   PWA with the new server.
