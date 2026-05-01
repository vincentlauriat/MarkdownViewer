#!/usr/bin/env bash
# Génère .xcodeproj via XcodeGen et build l'app Debug.
# Usage: ./Scripts/build.sh [run]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "✗ XcodeGen non installé. Installe-le : brew install xcodegen" >&2
  exit 1
fi

VENDOR="$ROOT/MarkdownViewer/Resources/web/vendor"
if [ ! -f "$VENDOR/markdown-it.min.js" ]; then
  echo "→ Vendor assets manquants, téléchargement…"
  "$ROOT/Scripts/fetch-vendor.sh"
fi

echo "→ Génération du projet Xcode…"
xcodegen generate

echo "→ Build Debug…"
xcodebuild -project MarkdownViewer.xcodeproj \
  -scheme MarkdownViewer \
  -configuration Debug \
  -derivedDataPath build \
  build CODE_SIGNING_ALLOWED=NO | tail -20

APP="$ROOT/build/Build/Products/Debug/MarkdownViewer.app"
echo ""
echo "✅ Build OK : $APP"

if [ "${1:-}" = "run" ]; then
  echo "→ Lancement…"
  open "$APP"
fi
