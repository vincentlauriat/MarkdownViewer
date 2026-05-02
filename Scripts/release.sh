#!/usr/bin/env bash
# Build a Release MarkdownViewer.app and package it as a distributable .dmg.
#
# Usage: ./Scripts/release.sh <version>
#   e.g. ./Scripts/release.sh 0.3.0
#
# Outputs MarkdownViewer-<version>.dmg at the repo root.
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

# 5. Stage to a clean directory, sign, package.
# Direct in-place codesign fails because Xcode's post-build `lsregister`
# adds `com.apple.provenance` xattrs, which `codesign --force --sign -`
# rejects with "resource fork, Finder information, or similar detritus
# not allowed". `ditto --noextattr` copies without xattrs and survives.
STAGING_DIR="$(mktemp -d)"
STAGING="$STAGING_DIR/MarkdownViewer.app"
echo "→ Staging to $STAGING_DIR"
ditto --norsrc --noextattr --noacl "$APP" "$STAGING"

echo "→ Ad-hoc signing"
codesign --force --sign - --timestamp=none --generate-entitlement-der "$STAGING"
codesign --verify --strict "$STAGING"

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

DMG_SIZE=$(ls -lh "$DMG" | awk '{print $5}')
echo ""
echo "✅ Built $DMG ($DMG_SIZE)"
echo ""
echo "Next steps to publish on GitHub:"
echo "  gh release create v$VERSION ./MarkdownViewer-$VERSION.dmg --generate-notes"
echo ""
echo "Or with custom notes:"
echo "  gh release create v$VERSION ./MarkdownViewer-$VERSION.dmg \\"
echo "      --title \"v$VERSION\" \\"
echo "      --notes-file release-notes-$VERSION.md"
