#!/usr/bin/env bash
# Télécharge les libs JS/CSS dans MarkdownViewer/Resources/web/vendor/
# Usage: ./Scripts/fetch-vendor.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/MarkdownViewer/Resources/web/vendor"
mkdir -p "$VENDOR/fonts"

# Versions épinglées
MARKDOWN_IT="14.1.0"
MIT_TASKLISTS="2.1.1"
HLJS="11.10.0"
KATEX="0.16.11"
MERMAID="10.9.1"
GH_MD_CSS="5.6.1"
DOMPURIFY="3.1.6"

dl() {
  echo "↓ ${2##*/}"
  curl -fsSL --retry 3 "$1" -o "$2"
}

dl "https://cdn.jsdelivr.net/npm/dompurify@${DOMPURIFY}/dist/purify.min.js" "$VENDOR/dompurify.min.js"
dl "https://cdn.jsdelivr.net/npm/markdown-it@${MARKDOWN_IT}/dist/markdown-it.min.js" "$VENDOR/markdown-it.min.js"
dl "https://cdn.jsdelivr.net/npm/markdown-it-task-lists@${MIT_TASKLISTS}/dist/markdown-it-task-lists.min.js" "$VENDOR/markdown-it-task-lists.min.js"
dl "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@${HLJS}/build/highlight.min.js" "$VENDOR/highlight.min.js"
dl "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@${HLJS}/build/styles/github.min.css" "$VENDOR/highlight-github.min.css"
dl "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@${HLJS}/build/styles/github-dark.min.css" "$VENDOR/highlight-github-dark.min.css"
dl "https://cdn.jsdelivr.net/npm/katex@${KATEX}/dist/katex.min.js" "$VENDOR/katex.min.js"
dl "https://cdn.jsdelivr.net/npm/katex@${KATEX}/dist/contrib/auto-render.min.js" "$VENDOR/katex-auto-render.min.js"
dl "https://cdn.jsdelivr.net/npm/katex@${KATEX}/dist/katex.min.css" "$VENDOR/katex.min.css"
dl "https://cdn.jsdelivr.net/npm/mermaid@${MERMAID}/dist/mermaid.min.js" "$VENDOR/mermaid.min.js"
dl "https://cdn.jsdelivr.net/npm/github-markdown-css@${GH_MD_CSS}/github-markdown.css" "$VENDOR/github-markdown.css"

# KaTeX fonts (woff2 suffit en pratique sur navigateurs modernes)
fonts=(
  KaTeX_AMS-Regular
  KaTeX_Caligraphic-Bold KaTeX_Caligraphic-Regular
  KaTeX_Fraktur-Bold KaTeX_Fraktur-Regular
  KaTeX_Main-Bold KaTeX_Main-BoldItalic KaTeX_Main-Italic KaTeX_Main-Regular
  KaTeX_Math-BoldItalic KaTeX_Math-Italic
  KaTeX_SansSerif-Bold KaTeX_SansSerif-Italic KaTeX_SansSerif-Regular
  KaTeX_Script-Regular
  KaTeX_Size1-Regular KaTeX_Size2-Regular KaTeX_Size3-Regular KaTeX_Size4-Regular
  KaTeX_Typewriter-Regular
)
for font in "${fonts[@]}"; do
  dl "https://cdn.jsdelivr.net/npm/katex@${KATEX}/dist/fonts/${font}.woff2" "$VENDOR/fonts/${font}.woff2"
done

echo ""
echo "✅ Vendor assets téléchargés dans : $VENDOR"
