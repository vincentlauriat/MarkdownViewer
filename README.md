<div align="center">

# MarkdownViewer

**A native macOS app to open `.md` files instantly from Finder.**

Double‑click a Markdown file. See it rendered. Edit it in your favourite editor — it reloads on the fly.

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos)
[![Release](https://img.shields.io/github/v/release/vincentlauriat/MarkdownViewer?color=brightgreen)](https://github.com/vincentlauriat/MarkdownViewer/releases/latest)
[![CI](https://github.com/vincentlauriat/MarkdownViewer/actions/workflows/ci.yml/badge.svg)](https://github.com/vincentlauriat/MarkdownViewer/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Document%20Group-purple.svg)](https://developer.apple.com/swiftui)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](#license)

</div>

---
<img width="1376" height="768" alt="image" src="https://github.com/user-attachments/assets/2467ea41-1514-40d6-bab5-8affd9bacebe" />

## Why

Pre‑installed Markdown previewers on macOS are either non‑existent (TextEdit shows raw text) or heavy (Electron‑based apps take seconds to launch). MarkdownViewer is built around a single goal: **open a `.md` in under 300 ms** while still rendering tables, syntax‑highlighted code, math and Mermaid diagrams the way GitHub does.

It is a true native macOS document app — multi‑window, multi‑file, dark‑mode aware, with the standard `Open Recent` menu and `Cmd+P` print dialog.

## Features

| | |
| --- | --- |
| 📄 **Native document app** | `DocumentGroup` + `FileDocument` — multi‑window, Open Recent, file association out of the box |
| ⚡ **Fast cold start** | Single SwiftUI scene, bundled web assets, no remote fetch on launch |
| 🔄 **Live reload** | Edit in VS Code / vim / any editor — preview updates in ≈130 ms (handles atomic saves) |
| 🌗 **Dark mode** | Follows the system theme automatically, syncs with `effectiveAppearance` |
| 🎨 **GitHub‑flavoured rendering** | `markdown-it` + GFM tables + task lists |
| 🌈 **Syntax highlighting** | `highlight.js` with GitHub light/dark themes |
| 🧮 **Math** | Inline `$E=mc^2$` and display `$$ … $$` via KaTeX |
| 📊 **Diagrams** | Mermaid graphs, sequence diagrams, flowcharts |
| ☑️ **Task lists** | Render `- [x]` / `- [ ]` natively |
| 🔍 **Find** | `Cmd+F` opens a native search bar, `Cmd+G` / `Cmd+Shift+G` to navigate |
| 🗂️ **Document outline** | Toolbar menu lists the document's headings (indented by level) — pick one to jump straight to it |
| 🖨️ **Print / Export PDF** | `Cmd+P` uses the native print dialog (the standard "Save as PDF" works), or *File → Export as PDF…* / the toolbar button to save a PDF directly without the print dialog |
| 📊 **Word count & reading time** | A status bar under the preview shows the document's word count and estimated reading time |
| 💾 **Save As…** | Always-visible *File → Save As…* item to save the current document to a new location (the native alternate hidden behind ⌥ still works too) |
| ✏️ **Editor mode** | Toggle Preview / Split / Source via toolbar (`Cmd+/` cycles), syntax-highlighted `NSTextView`, native Cmd+S / dirty indicator / undo / redo |
| 📐 **Line numbers gutter** | Native `NSRulerView` gutter on Source and Split modes — width grows with the document, soft-wrapped continuations are not numbered (Xcode / VS Code convention) |
| 🎯 **Current-line highlight** | The cursor's line number is rendered in bold + accent color in the gutter, follows the caret in real time. Toggle from *View* if you prefer it off |
| 🔎 **Content zoom** | `⌘+` / `⌘-` / `⌘0` zoom the rendered preview (50 % → 300 %). Persisted per window, so each document keeps its own zoom level |
| 🎨 **Theme picker** | Auto (system) / GitHub Light / GitHub Dark / Sepia — from the palette menu in the toolbar, persisted per window |
| 🏷️ **Frontmatter toggle** | Auto-detects YAML frontmatter (Obsidian / Tolaria / Jekyll) and lets you hide it (`⇧⌘Y`) for a cleaner read |
| 👁️ **Quick Look** | Select a `.md` in Finder and press **Space** — full rendering (code, math, diagrams, dark mode) without opening the app |
| 🚀 **One-click auto-update** | Sparkle 2 + Apple-notarized DMGs + EdDSA signature — *Check for Updates…* prompts before downloading, then swaps and relaunches the new version automatically |
| 📖 **In-app Help & What's New** | Help (`⌘?`) and *What's New…* fetch the live README and release notes from GitHub and render them through the same Markdown pipeline as documents |
| 🔒 **Safe by default** | `markdown-it` HTML disabled, DOMPurify on top, all rendering offline (`file://`) |
| 🛟 **Crash recovery** | A detached watchdog relaunches the app and reopens your documents if a rare rendering crash ever takes the process down |

## Install

Grab the latest pre-built `.dmg` from the [GitHub Releases page](https://github.com/vincentlauriat/MarkdownViewer/releases/latest), mount it, and drag `MarkdownViewer.app` to `/Applications`.

Releases from **v0.5.1** onwards are signed with an Apple Developer ID, built with the Hardened Runtime, and notarized + stapled by Apple — they launch by double-click without any Gatekeeper warning, even offline.

Once installed, **Sparkle** (added in v0.6.0) takes over: every future release is downloaded, signed-checked, swapped and relaunched automatically when you click *Install and Relaunch* in the *Check for Updates…* dialog. No more drag-and-drop into `/Applications`.

## Quick start (build from source)

**Requirements:** macOS 13 (Ventura) or later, Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/vincentlauriat/MarkdownViewer.git
cd MarkdownViewer
./Scripts/build.sh run
```

That single script downloads vendored JS/CSS, generates the Xcode project, builds in Debug and launches the app on a sample document.

## Set as default `.md` handler

After the first build, the app is automatically registered with `LaunchServices`. To make it the default for every Markdown file:

1. In Finder, right‑click any `.md` file → **Get Info**
2. Expand **Open with** → choose **MarkdownViewer**
3. Click **Change All…**

From now on, double‑clicking any `.md` opens it in MarkdownViewer in a new window.

<img width="1376" height="768" alt="image" src="https://github.com/user-attachments/assets/6fcb6453-2e02-428d-abe1-22e97903c876" />

## Architecture

```
┌──────────────────────────────────────────────────┐
│                   macOS Finder                   │
│            (double‑click on file.md)             │
└──────────────────────┬───────────────────────────┘
                       │ Launch Services
                       ▼
┌──────────────────────────────────────────────────┐
│      MarkdownViewer.app  (SwiftUI + AppKit)      │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │            DocumentGroup                 │    │
│  │   (multi-window, Open Recent, save)      │    │
│  └──────────────────┬───────────────────────┘    │
│                     │                            │
│  ┌──────────────────▼───────────────────────┐    │
│  │      MarkdownDocument: FileDocument      │    │
│  │   readableContentTypes = [.markdown]     │    │
│  └──────────────────┬───────────────────────┘    │
│                     │                            │
│  ┌──────────────────▼───────────────────────┐    │
│  │       ContentView ⊕ FindBar overlay      │    │
│  └──────────────────┬───────────────────────┘    │
│                     │                            │
│  ┌──────────────────▼───────────────────────┐    │
│  │     WebView (NSViewRepresentable)        │    │
│  │  ┌────────────────────────────────────┐  │    │
│  │  │ Coordinator                        │  │    │
│  │  │  ├─ FileWatcher (DispatchSource)   │  │    │
│  │  │  ├─ Theme observer (KVO)           │  │    │
│  │  │  └─ Notification observers         │  │    │
│  │  └────────────────────────────────────┘  │    │
│  │              ┌─────────┐                 │    │
│  │              │WKWebView│                 │    │
│  │              └────┬────┘                 │    │
│  └───────────────────┼──────────────────────┘    │
└──────────────────────┼───────────────────────────┘
                       │ evaluateJavaScript
                       ▼
┌──────────────────────────────────────────────────┐
│   Resources/web/  (bundled, file://)             │
│   ├── index.html                                 │
│   ├── render.js                                  │
│   └── vendor/                                    │
│       ├── markdown-it · markdown-it-task-lists   │
│       ├── highlight.js + GitHub themes           │
│       ├── katex + auto-render + fonts            │
│       ├── mermaid                                │
│       ├── dompurify                              │
│       └── github-markdown.css                    │
└──────────────────────────────────────────────────┘
```

### Tech stack

| Layer | Choice | Reason |
| --- | --- | --- |
| Language | Swift 5.9 | Native macOS, future iOS/iPadOS |
| UI | SwiftUI | Cross‑platform Apple, multi‑window for free |
| Document model | `DocumentGroup` + `FileDocument` | Native file association, multi‑window, Open Recent, iCloud Drive |
| Rendering host | `WKWebView` via `NSViewRepresentable` | Lets us reuse the rich JS Markdown ecosystem |
| Markdown parser | [markdown-it](https://github.com/markdown-it/markdown-it) 14 | CommonMark + GFM, plugin‑friendly |
| Code highlight | [highlight.js](https://highlightjs.org) 11 | Tiny, ships GitHub themes |
| Math | [KaTeX](https://katex.org) 0.16 | Server‑grade quality, fast |
| Diagrams | [Mermaid](https://mermaid.js.org) 10 | De‑facto standard |
| Sanitisation | [DOMPurify](https://github.com/cure53/DOMPurify) 3 | Defence in depth on top of `html: false` |
| Style | [github-markdown-css](https://github.com/sindresorhus/github-markdown-css) 5 | Familiar look, light + dark variants |
| File watching | `DispatchSource.makeFileSystemObjectSource` | Low‑level, robust, debounced |
| Project file | [XcodeGen](https://github.com/yonaskolb/XcodeGen) | YAML source of truth, no merge pain on `.pbxproj` |

## Project layout

```
MarkdownViewer/
├── project.yml                    # XcodeGen spec (source of truth, macOS + iOS + Quick Look targets)
├── appcast.xml                    # Sparkle 2 update feed (regenerated by release.sh)
├── MarkdownViewer/
│   ├── Sources/
│   │   ├── MarkdownViewerApp.swift     # @main, DocumentGroup, menu commands, Sparkle updater
│   │   ├── MarkdownDocument.swift      # FileDocument + UTType.markdown
│   │   ├── ContentView.swift           # Toolbar + WebView / MarkdownEditor + FindBar overlay
│   │   ├── ViewMode.swift              # enum Preview / Split / Source
│   │   ├── WebView.swift               # NS/UIViewRepresentable around WKWebView
│   │   ├── MarkdownEditor.swift        # NS/UITextView wrapper + NSTextStorage highlighter
│   │   ├── LineNumberRulerView.swift   # NSRulerView gutter + current-line highlight (macOS)
│   │   ├── FindBar.swift               # SwiftUI floating find bar
│   │   ├── FileWatcher.swift           # DispatchSource-based live reload (macOS)
│   │   ├── HelpWindows.swift           # In-app Help / What's New / About windows (macOS)
│   │   └── Shared/WebPipeline.swift    # Helpers shared with the Quick Look extension
│   └── Resources/
│       ├── web/                        # index.html + render.js + vendor/
│       └── Assets.xcassets/            # AppIcon (macOS .icns + iOS marketing 1024)
├── MarkdownViewerQL/
│   ├── Sources/PreviewViewController.swift   # Quick Look extension (same web pipeline)
│   └── MarkdownViewerQL.entitlements         # Sandbox + read-only file access
├── MarkdownViewerTests/                # Unit tests (WebPipeline, Highlighter, FileWatcher)
├── .github/workflows/ci.yml            # CI: build + tests (macOS), build (iOS Simulator)
├── Scripts/
│   ├── fetch-vendor.sh                 # Downloads pinned JS/CSS from jsDelivr
│   ├── build.sh                        # End-to-end: fetch → xcodegen → xcodebuild
│   ├── make-icon.swift                 # Generates the AppIcon PNGs from a single Swift draw
│   ├── make-dmg-background.swift       # Generates the DMG installer background image
│   └── release.sh                      # Release pipeline: Developer ID signing → notarization
│                                       # → stapling → DMG layout → Sparkle EdDSA → appcast.xml
├── release/                            # DMGs + release notes (local artifacts, gitignored)
├── docs/index.html                     # GitHub Pages landing page
├── sample.md                           # Stress-test document covering every feature
└── sample-long.md                      # 541-line stress doc for the line-numbers gutter
```

## Development

```bash
# Regenerate the Xcode project after editing project.yml
xcodegen generate

# Build only
xcodebuild -project MarkdownViewer.xcodeproj -scheme MarkdownViewer -configuration Debug build

# Run the unit tests
xcodebuild -project MarkdownViewer.xcodeproj -scheme MarkdownViewer -configuration Debug test

# Inspect runtime logs (the app uses os.Logger with a custom subsystem)
log show --predicate 'subsystem == "com.vincent.MarkdownViewer"' --info --last 1m
```

Debug builds are signed ad‑hoc (`CODE_SIGN_IDENTITY=-`), which is enough for local development. Published releases go through `Scripts/release.sh`, which re-signs everything with a Developer ID certificate + Hardened Runtime, notarizes and staples the DMG, then signs it with the Sparkle EdDSA key and regenerates `appcast.xml`.

## Roadmap

- [x] **Viewer (v0.1)** — file association, rendering, live reload, find, print, M↓ icon
- [x] **Editor (v0.2)** — Preview / Split / Source toggle, native `Cmd+S`, dirty indicator, undo / redo, syntax-highlighted source
- [x] **Frontmatter toggle (v0.2.x)** — detect & hide YAML metadata (Obsidian / Tolaria style)
- [x] **iPadOS / iOS scaffold (v0.3)** — second target with `UIViewRepresentable` wrappers, shared sources via `#if os(macOS|iOS)`, asset catalog extended with iOS marketing icon. Runtime smoke-test still pending an App Store distribution decision.
- [x] **In-app updater (v0.4)** — GitHub Releases polling, semver-numeric compare, `Check for Updates…` menu, `Scripts/release.sh` to package signed DMGs
- [x] **Line numbers gutter (v0.5)** — `NSRulerView` subclass on the source editor, soft-wrap-aware, dynamic width
- [x] **Notarized releases (v0.5.1)** — Developer ID + Hardened Runtime + Apple notarization + stapler ticket
- [x] **Sparkle 2 auto-update + in-app Help / What's New / About (v0.6)** — one-click install-and-relaunch, internal windows for README and release notes, custom About with View on GitHub button
- [x] **Content zoom + current-line highlight (v0.7)** — `⌘+` / `⌘-` / `⌘0` zooms the preview (per-window), the gutter highlights the cursor's line in bold + accent color
- [x] **Quick Look extension (v0.8)** — preview in Finder with the spacebar, same rendering pipeline as the app
- [x] **Crash workaround (v0.8.1)** — pins the window to sRGB 8-bit to dodge a macOS QuartzCore/Metal half-float shader bug on Apple Silicon (reported to Apple)
- [x] **Theme picker (v0.9)** — Auto / GitHub Light / GitHub Dark / Sepia, persisted per window
- [x] **Crash recovery + visible Save As (v0.9.1)** — detached watchdog relaunches the app and reopens documents after a rare rendering crash; always-visible *File → Save As…*
- [ ] **Floating table of contents** — for long docs

## Contributing

This is a personal project but contributions are welcome. The codebase is small (~1,600 lines of Swift) and built around a single design principle: **delegate to native macOS APIs whenever possible, drop down to JavaScript only for what `WKWebView` already renders for free.**

Open an issue first if you plan to add a major feature.

## License

MIT — see [LICENSE](LICENSE).
