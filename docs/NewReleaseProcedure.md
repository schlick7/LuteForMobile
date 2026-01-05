# Project Folder
- cd ~/LuteForAndroid/

# Update Version
- Update pubspec.yaml

# Build android
- Flutter build apk
- rename to LuteForMobile-vX.X.X

# Build PWA

## Build the web app first
flutter build web

## Add script
cp setup_pwa.py build/web/

## Fix permissions
cd build/web
sudo find build/web -type f -exec chmod 644 {} \;
sudo find build/web -type d -exec chmod 755 {} \;
sudo chown -R $USER:$USER build/web

## Create the zip
zip -r ../../LuteForMobilePWA.zip * -x "*.last_build_id"
