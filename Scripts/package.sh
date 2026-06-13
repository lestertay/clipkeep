#!/usr/bin/env bash
# Build, sign (Developer ID), notarize, staple, and produce a .dmg.
# Prerequisites (set as env vars before running):
#   DEV_ID_APP="Developer ID Application: Your Name (TEAMID)"
#   NOTARY_PROFILE="clipkeep-notary"   # created via: xcrun notarytool store-credentials
set -euo pipefail
cd "$(dirname "$0")/.."

: "${DEV_ID_APP:?set DEV_ID_APP to your Developer ID Application identity}"
: "${NOTARY_PROFILE:?set NOTARY_PROFILE to your stored notarytool profile name}"

APP_NAME="ClipKeep"
BUILD_DIR="App/build"
EXPORT_DIR="dist"
rm -rf "$EXPORT_DIR" && mkdir -p "$EXPORT_DIR"

echo "==> Generating project"
./Scripts/bootstrap.sh

echo "==> Archiving (Release)"
cd App
xcodebuild -scheme "$APP_NAME" -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "../$EXPORT_DIR/$APP_NAME.xcarchive" \
  CODE_SIGN_IDENTITY="$DEV_ID_APP" archive
cd ..

APP_PATH="$EXPORT_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app"

echo "==> Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "==> Creating dmg"
DMG_PATH="$EXPORT_DIR/$APP_NAME.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

echo "==> Notarizing"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> Stapling"
xcrun stapler staple "$DMG_PATH"
xcrun stapler staple "$APP_PATH"

echo "==> Done: $DMG_PATH"
