#!/usr/bin/env bash
# Build a Release MarkdownViewer.app, Developer ID sign with Hardened Runtime,
# notarize via Apple, staple the ticket, and package it as a distributable .dmg.
#
# Usage: ./Scripts/release.sh <version>
#   e.g. ./Scripts/release.sh 0.5.1
#
# Prerequisites (one-time setup, see MEMORY.md):
#   - "Developer ID Application: Vincent LAURIAT (KFLACS69T9)" certificate in
#     the login keychain (created via Xcode → Settings → Accounts → Manage
#     Certificates).
#   - notarytool credentials stored under the keychain profile
#     "MarkdownViewer-Notary":
#       xcrun notarytool store-credentials "MarkdownViewer-Notary" \
#         --apple-id "vincent@lauriat.fr" --team-id "KFLACS69T9"
#
# Override defaults if needed:
#   SIGNING_IDENTITY="Developer ID Application: …"  ./Scripts/release.sh 0.5.1
#   NOTARY_PROFILE="MarkdownViewer-Notary"          ./Scripts/release.sh 0.5.1
#
# Outputs MarkdownViewer-<version>.dmg at the repo root, fully notarized.
# Does NOT push to GitHub — prints the suggested `gh release create` command.

set -euo pipefail

VERSION="${1:?Usage: ./Scripts/release.sh <version>  (e.g. ./Scripts/release.sh 0.3.0)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 1. Sanity check: project.yml must declare the same MARKETING_VERSION
if ! grep -q "MARKETING_VERSION: \"$VERSION\"" project.yml; then
  echo "✗ MARKETING_VERSION in project.yml does not match $VERSION" >&2
  echo "  Found:" >&2
  grep "MARKETING_VERSION" project.yml | sed 's/^/    /' >&2
  echo "  Bump project.yml first, then re-run." >&2
  exit 1
fi

# 2. Vendor assets
VENDOR="$ROOT/MarkdownViewer/Resources/web/vendor"
if [ ! -f "$VENDOR/markdown-it.min.js" ]; then
  echo "→ Vendor assets missing, downloading…"
  "$ROOT/Scripts/fetch-vendor.sh"
fi

# 3. Regenerate xcodeproj
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "✗ XcodeGen not installed. brew install xcodegen" >&2
  exit 1
fi
echo "→ xcodegen generate"
xcodegen generate >/dev/null

# 4. Build Release
# CODE_SIGNING_ALLOWED=NO works around the macOS Sequoia
# `com.apple.provenance` xattr that breaks ad-hoc codesign in CLI.
# We sign manually below after a clean xattr scrub.
echo "→ xcodebuild Release"
xcodebuild -project MarkdownViewer.xcodeproj \
  -scheme MarkdownViewer \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tail -5

APP="$ROOT/build/Build/Products/Release/MarkdownViewer.app"
if [ ! -d "$APP" ]; then
  echo "✗ Build did not produce $APP" >&2
  exit 1
fi

# 5. Stage to a clean directory, Developer ID sign with Hardened Runtime, package.
# Direct in-place codesign fails because Xcode's post-build `lsregister`
# adds `com.apple.provenance` xattrs, which `codesign --force` rejects with
# "resource fork, Finder information, or similar detritus not allowed".
# `ditto --noextattr` copies without xattrs and survives.
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Vincent LAURIAT (KFLACS69T9)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-MarkdownViewer-Notary}"

STAGING_DIR="$(mktemp -d)"
STAGING="$STAGING_DIR/MarkdownViewer.app"
echo "→ Staging to $STAGING_DIR"
ditto --norsrc --noextattr --noacl "$APP" "$STAGING"

echo "→ Codesigning with Developer ID + Hardened Runtime"
codesign --force --options runtime --timestamp \
  --sign "$SIGNING_IDENTITY" \
  "$STAGING"
codesign --verify --strict --deep "$STAGING"

DMG="$ROOT/MarkdownViewer-$VERSION.dmg"
rm -f "$DMG"
echo "→ hdiutil create $DMG"
hdiutil create \
  -volname "MarkdownViewer $VERSION" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG" >/dev/null

rm -rf "$STAGING_DIR"

# 6. Notarize the DMG with Apple, then staple the ticket so the app
# launches on machines without internet access.
echo "→ Submitting $DMG to Apple notary service (this takes 2–5 min)"
xcrun notarytool submit "$DMG" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

echo "→ Stapling notarization ticket to the DMG"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

DMG_SIZE=$(ls -lh "$DMG" | awk '{print $5}')
echo ""
echo "✅ Built, signed, notarized and stapled: $DMG ($DMG_SIZE)"
echo ""
echo "Next steps to publish on GitHub:"
echo "  gh release create v$VERSION ./MarkdownViewer-$VERSION.dmg --generate-notes"
echo ""
echo "Or with custom notes:"
echo "  gh release create v$VERSION ./MarkdownViewer-$VERSION.dmg \\"
echo "      --title \"v$VERSION\" \\"
echo "      --notes-file release-notes-$VERSION.md"
