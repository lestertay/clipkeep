#!/usr/bin/env bash
# Build ClipKeep for local development with a STABLE code signature.
#
# Why: an ad-hoc signature changes identity on every rebuild, which makes macOS
# forget the Accessibility grant each time (auto-paste + caret positioning then
# silently fail). Signing with your Apple Development identity gives a stable
# designated requirement, so you grant Accessibility once and it persists across
# rebuilds. The identity/team are auto-detected, so nothing personal is committed.
set -euo pipefail
cd "$(dirname "$0")/.."

./Scripts/bootstrap.sh

# Find a development signing identity and use it by SHA-1 hash (avoids name
# resolution to "Mac Development" + provisioning-profile lookups, and keeps any
# personal details out of this committed script).
HASH=$(security find-identity -p codesigning -v | awk '/Apple Development|Developer ID Application/{print $2; exit}')

cd App
if [ -n "$HASH" ]; then
  echo "==> Signing with identity $HASH (manual) — stable, Accessibility grant persists"
  xcodebuild -scheme ClipKeep -destination 'platform=macOS' -derivedDataPath build \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$HASH" PROVISIONING_PROFILE_SPECIFIER="" \
    build
else
  echo "==> No Apple Development identity found — falling back to ad-hoc."
  echo "    (The Accessibility grant will reset on each rebuild; create an Apple"
  echo "     Development cert in Xcode, or a self-signed Code Signing cert, to fix.)"
  xcodebuild -scheme ClipKeep -destination 'platform=macOS' -derivedDataPath build build
fi

echo "==> Built: App/build/Build/Products/Debug/ClipKeep.app"
