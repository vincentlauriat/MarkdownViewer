<div align="center">

# MarkdownViewer

**A native macOS app to open `.md` files instantly from Finder.**

Double‑click a Markdown file. See it rendered. Edit it in your favourite editor — it reloads on the fly.

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos)
[![Release](https://img.shields.io/github/v/release/vincentlauriat/MarkdownViewer?color=brightgreen)](https://github.com/vincentlauriat/MarkdownViewer/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Document%20Group-purple.svg)](https://developer.apple.com/swiftui)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](#license)

</div>

---

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
| 🖨️ **Print / Export PDF** | `Cmd+P` uses the native print dialog (the standard "Save as PDF" works) |
| ✏️ **Editor mode** | Toggle Preview / Split / Source via toolbar (`Cmd+/` cycles), syntax-highlighted `NSTextView`, native Cmd+S / dirty indicator / undo / redo |
| 📐 **Line numbers gutter** | Native `NSRulerView` gutter on Source and Split modes — width grows with the document, soft-wrapped continuations are not numbered (Xcode / VS Code convention) |
| 🏷️ **Frontmatter toggle** | Auto-detects YAML frontmatter (Obsidian / Tolaria / Jekyll) and lets you hide it (`⇧⌘Y`) for a cleaner read |
| 🔄 **In-app updater** | Checks GitHub Releases on launch (debounced 7 days) and offers a `Check for Updates…` menu — semver-compared, ad-hoc-signed DMGs |
| 🔒 **Safe by default** | `markdown-it` HTML disabled, DOMPurify on top, all rendering offline (`file://`) |

## Install

Grab the latest pre-built `.dmg` from the [GitHub Releases page](https://github.com/vincentlauriat/MarkdownViewer/releases/latest), mount it, and drag `MarkdownViewer.app` to `/Applications`.

Releases from **v0.5.1** onwards are signed with an Apple Developer ID, built with the Hardened Runtime, and notarized + stapled by Apple — they launch by double-click without any Gatekeeper warning, even offline. Older versions (v0.3.0, v0.5.0) were ad-hoc signed and need a one-time right-click → **Open** on first launch.

Once installed, MarkdownViewer's built-in updater (added in v0.3.0) will prompt you when a new release is published.

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
├── project.yml                    # XcodeGen spec (source of truth, macOS + iOS targets)
├── MarkdownViewer/
│   ├── Sources/
│   │   ├── MarkdownViewerApp.swift     # @main, DocumentGroup, menu commands
│   │   ├── MarkdownDocument.swift      # FileDocument + UTType.markdown
│   │   ├── ContentView.swift           # Toolbar + WebView / MarkdownEditor + FindBar overlay
│   │   ├── ViewMode.swift              # enum Preview / Split / Source
│   │   ├── WebView.swift               # NS/UIViewRepresentable around WKWebView
│   │   ├── MarkdownEditor.swift        # NS/UITextView wrapper + NSTextStorage highlighter
│   │   ├── LineNumberRulerView.swift   # NSRulerView gutter (macOS only, #if os(macOS))
│   │   ├── FindBar.swift               # SwiftUI floating find bar
│   │   ├── FileWatcher.swift           # DispatchSource-based live reload (macOS)
│   │   └── UpdateChecker.swift         # GitHub Releases polling + NSAlert (macOS)
│   └── Resources/
│       ├── web/                        # index.html + render.js + vendor/
│       └── Assets.xcassets/            # AppIcon (macOS .icns + iOS marketing 1024)
├── Scripts/
│   ├── fetch-vendor.sh                 # Downloads pinned JS/CSS from jsDelivr
│   ├── build.sh                        # End-to-end: fetch → xcodegen → xcodebuild
│   ├── make-icon.swift                 # Generates the AppIcon PNGs from a single Swift draw
│   └── release.sh                      # Build Release + ad-hoc codesign + DMG packaging
├── sample.md                           # Stress-test document covering every feature
└── sample-long.md                      # 541-line stress doc for the line-numbers gutter
```

## Development

```bash
# Regenerate the Xcode project after editing project.yml
xcodegen generate

# Build only
xcodebuild -project MarkdownViewer.xcodeproj -scheme MarkdownViewer -configuration Debug build

# Inspect runtime logs (the app uses os.Logger with a custom subsystem)
log show --predicate 'subsystem == "com.vincent.MarkdownViewer"' --info --last 1m
```

The bundle is signed ad‑hoc (`CODE_SIGN_IDENTITY=-`) which is enough for personal use. For wider distribution, set a Developer ID via `DEVELOPMENT_TEAM` in `project.yml`.

## Roadmap

- [x] **Viewer (v0.1)** — file association, rendering, live reload, find, print, M↓ icon
- [x] **Editor (v0.2)** — Preview / Split / Source toggle, native `Cmd+S`, dirty indicator, undo / redo, syntax-highlighted source
- [x] **Frontmatter toggle (v0.2.x)** — detect & hide YAML metadata (Obsidian / Tolaria style)
- [x] **iPadOS / iOS scaffold (v0.3)** — second target with `UIViewRepresentable` wrappers, shared sources via `#if os(macOS|iOS)`, asset catalog extended with iOS marketing icon. Runtime smoke-test still pending an App Store distribution decision.
- [x] **In-app updater (v0.4)** — GitHub Releases polling, semver-numeric compare, `Check for Updates…` menu, `Scripts/release.sh` to package signed DMGs
- [x] **Line numbers gutter (v0.5)** — `NSRulerView` subclass on the source editor, soft-wrap-aware, dynamic width
- [ ] **Quick Look extension** — preview in Finder with the spacebar
- [ ] **Theme picker** — GitHub light / dark / sepia / custom
- [ ] **Floating table of contents** — for long docs
- [ ] **Current-line highlight** in the gutter (toggleable)

## Contributing

This is a personal project but contributions are welcome. The codebase is small (~500 lines of Swift) and built around a single design principle: **delegate to native macOS APIs whenever possible, drop down to JavaScript only for what `WKWebView` already renders for free.**

Open an issue first if you plan to add a major feature.

## License

MIT — see [LICENSE](LICENSE).
