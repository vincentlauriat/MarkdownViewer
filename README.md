<div align="center">

# MarkdownViewer

**A native macOS app to open `.md` files instantly from Finder.**

Double‑click a Markdown file. See it rendered. Edit it in your favourite editor — it reloads on the fly.

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos)
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
| 🔒 **Safe by default** | `markdown-it` HTML disabled, DOMPurify on top, all rendering offline (`file://`) |

## Quick start

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
├── project.yml                    # XcodeGen spec (source of truth)
├── MarkdownViewer/
│   ├── Sources/
│   │   ├── MarkdownViewerApp.swift   # @main, DocumentGroup, menu commands
│   │   ├── MarkdownDocument.swift    # FileDocument + UTType.markdown
│   │   ├── ContentView.swift         # WebView + FindBar overlay
│   │   ├── WebView.swift             # NSViewRepresentable around WKWebView
│   │   ├── FindBar.swift             # SwiftUI floating find bar
│   │   └── FileWatcher.swift         # DispatchSource-based live reload
│   └── Resources/
│       ├── web/                      # index.html + render.js + vendor/
│       └── Assets.xcassets/          # AppIcon, AccentColor
├── Scripts/
│   ├── fetch-vendor.sh               # Downloads pinned JS/CSS from jsDelivr
│   └── build.sh                      # End-to-end: fetch → xcodegen → xcodebuild
└── sample.md                         # Stress-test document covering every feature
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

- [x] Viewer (v1) — file association, rendering, live reload, find, print
- [ ] Editor (v2) — toggle preview / source, save with `Cmd+S`, native undo
- [ ] iPadOS / iOS (v3) — same `DocumentGroup`, compact UI
- [ ] Quick Look extension — preview in Finder with the spacebar
- [ ] Theme picker — GitHub light/dark/sepia/custom
- [ ] Floating table of contents

## Contributing

This is a personal project but contributions are welcome. The codebase is small (~500 lines of Swift) and built around a single design principle: **delegate to native macOS APIs whenever possible, drop down to JavaScript only for what `WKWebView` already renders for free.**

Open an issue first if you plan to add a major feature.

## License

MIT — see [LICENSE](LICENSE).
