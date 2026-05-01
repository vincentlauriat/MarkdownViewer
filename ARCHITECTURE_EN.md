# Architecture — MarkdownViewer

## Overview

```
┌─────────────────────────────────────────────────┐
│                   macOS Finder                  │
│            (double-click on file.md)            │
└─────────────────────┬───────────────────────────┘
                      │ Launch Services
                      ▼
┌─────────────────────────────────────────────────┐
│      MarkdownViewer.app  (SwiftUI + AppKit)     │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │            DocumentGroup                │    │
│  │   (multi-window, Open Recent, save)     │    │
│  └─────────────────┬───────────────────────┘    │
│                    │                            │
│  ┌─────────────────▼───────────────────────┐    │
│  │      MarkdownDocument: FileDocument     │    │
│  │   readableContentTypes = [.markdown]    │    │
│  └─────────────────┬───────────────────────┘    │
│                    │                            │
│  ┌─────────────────▼───────────────────────┐    │
│  │       ContentView ⊕ FindBar overlay     │    │
│  └─────────────────┬───────────────────────┘    │
│                    │                            │
│  ┌─────────────────▼───────────────────────┐    │
│  │     WebView (NSViewRepresentable)       │    │
│  │  ┌───────────────────────────────────┐  │    │
│  │  │ Coordinator                       │  │    │
│  │  │  ├─ FileWatcher (DispatchSource)  │  │    │
│  │  │  ├─ Theme observer (KVO)          │  │    │
│  │  │  └─ Notification observers        │  │    │
│  │  └───────────────────────────────────┘  │    │
│  │              ┌─────────┐                │    │
│  │              │WKWebView│                │    │
│  │              └────┬────┘                │    │
│  └───────────────────┼──────────────────────┘   │
└──────────────────────┼──────────────────────────┘
                       │ evaluateJavaScript
                       ▼
┌─────────────────────────────────────────────────┐
│   Web bundle (Resources/web/, file://)          │
│   ├── index.html                                │
│   ├── render.js                                 │
│   └── vendor/                                   │
│       ├── markdown-it · markdown-it-task-lists  │
│       ├── highlight.js + GitHub themes          │
│       ├── katex + auto-render + fonts           │
│       ├── mermaid                               │
│       ├── dompurify                             │
│       └── github-markdown.css                   │
└─────────────────────────────────────────────────┘
```

## Tech stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | Swift 5.9+ | Native macOS, future iOS / iPadOS |
| UI | SwiftUI | Cross-platform across Apple devices, multi-window for free |
| Document model | `DocumentGroup` + `FileDocument` | Native file association, Open Recent menu, iCloud Drive support |
| Render host | `WKWebView` via `NSViewRepresentable` | Lets us reuse the rich JS Markdown ecosystem |
| Markdown parser | `markdown-it` (JS) | CommonMark + GFM, plugin-friendly (tables, task lists) |
| Code highlighting | `highlight.js` (JS) | Lightweight (~100 KB), ships GitHub light/dark themes |
| Math | `KaTeX` (JS) | Server-grade quality, fast |
| Diagrams | `Mermaid` (JS) | De-facto standard |
| Sanitisation | `DOMPurify` (JS) | Defence in depth on top of `markdown-it` `html: false` |
| Style | `github-markdown-css` | Familiar look, light + dark variants |
| File watching | `DispatchSource.makeFileSystemObjectSource` | Low-level, robust, debounced |
| Project file | `XcodeGen` | YAML source of truth, no `.pbxproj` merge pain |

## Swift modules

```
MarkdownViewer/Sources/
├── MarkdownViewerApp.swift   — @main, DocumentGroup, menu commands
├── MarkdownDocument.swift    — FileDocument + UTType.markdown
├── ContentView.swift         — WebView + FindBar overlay
├── WebView.swift             — NSViewRepresentable around WKWebView
│                               (Coordinator owns FileWatcher + observers)
├── FindBar.swift             — SwiftUI floating find bar (NSSearchField-like)
└── FileWatcher.swift         — DispatchSource-based live reload

MarkdownViewer/Resources/
└── web/
    ├── index.html            — host page
    ├── render.js             — markdown-it + highlight.js + KaTeX + Mermaid pipeline
    └── vendor/               — pinned third-party libs (downloaded by Scripts/fetch-vendor.sh)
```

## Data flow

### Opening a file
1. Finder → Launch Services → `MarkdownViewer.app`
2. `DocumentGroup` instantiates a `MarkdownDocument` (reads UTF-8)
3. `ContentView` renders `WebView(markdown: document.text)` plus the optional `FindBar` overlay
4. `WebView.makeNSView` builds a `WKWebView` and calls `loadFileURL(index.html, allowingReadAccessTo: web/)`
5. On `webView(_:didFinish:)`, the Coordinator injects `window.renderMarkdown(<json string>)`
6. `render.js` parses Markdown, highlights code via `highlight.js`, renders math via KaTeX, replaces ` ```mermaid ` blocks with Mermaid diagrams

### Live reload
1. Coordinator picks up `webView.window?.representedURL` (set by `DocumentGroup` once the window is attached)
2. `FileWatcher` opens an `O_EVTONLY` file descriptor and a `DispatchSource` with mask `[.write, .delete, .rename, .extend]`
3. On any event the change is debounced for 120 ms, then the file is re-read and `renderMarkdown(...)` re-injected
4. On `.delete` / `.rename` (atomic save: vim, VS Code), the watcher closes the old fd and opens a new one against the same path before reloading
5. Measured latency: ≈130 ms between disk change and re-render

### Dark mode
- KVO observes `NSApp.effectiveAppearance`
- On change, `webView.evaluateJavaScript("window.setTheme('dark' | 'light')")`
- `setTheme()` toggles `body[data-theme]`, switches the active `highlight.js` stylesheet, and re-initialises Mermaid with the matching theme

### Find
1. `Cmd+F` (menu command) posts `.toggleFindBar` → `ContentView` shows the overlay with `@FocusState`
2. Typing posts `.findRequest(query, forward: true)` on every keystroke
3. `Cmd+G` / `Cmd+Shift+G` post `.findNext` / `.findPrevious` (re-uses the last query)
4. Coordinator filters by `webView.window?.isKeyWindow` so inactive windows stay quiet, then calls `WKWebView.find(_:configuration:)` (native, macOS 12+)

### Print / Export PDF
1. `Cmd+P` (menu command) posts `.printActiveDocument`
2. Coordinator builds an `NSPrintInfo`, asks `webView.printOperation(with:)` for an `NSPrintOperation`, runs it modally against the active window
3. The native macOS print dialog handles "Save as PDF" via the standard PDF dropdown — no extra code required

## Things to watch

- **`WKWebView` security**: JavaScript is enabled, `markdown-it` runs with `html: false`, and DOMPurify wraps the output before injection — no untrusted HTML reaches the DOM. Navigation is intercepted in `decidePolicyFor`: external link clicks open via `NSWorkspace.shared.open`, everything else is denied.
- **Local relative images**: must be resolved against the file's parent directory. Currently delegated to `WKWebView` since the app is not sandboxed; if sandbox is enabled later, a security-scoped bookmark on the parent directory is required and `loadFileURL(_:allowingReadAccessTo:)` must be reapplied.
- **Large files**: above ~500 KB the Markdown render starts to feel sluggish. A progressive renderer (chunks, intersection observer) is the right path but is out of scope for v1.
- **Cross-platform**: keep `AppKit` imports out of the model layer. `MarkdownDocument` and `FileWatcher` are already AppKit-free; the iOS port mostly needs a UIKit-flavoured `WebView` wrapper and a redesigned `FindBar` for compact width classes.
- **XcodeGen `resources:`**: there is *no* top-level `resources:` key. Resources go inside `sources:` with `buildPhase: resources`. Misconfiguring this silently produces an `.app` bundle without any `Contents/Resources/`.
- **Swift 6 concurrency + `NotificationCenter`**: the closure passed to `addObserver` does *not* inherit `@MainActor` from the calling context. The `observe(_:action:)` helper types its parameter as `@escaping @MainActor @Sendable (Notification) -> Void` so the inference flows down to call sites without forcing `@MainActor in` everywhere.
