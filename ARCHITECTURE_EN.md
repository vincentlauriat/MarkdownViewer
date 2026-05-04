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
├── MarkdownViewerApp.swift     — @main, DocumentGroup(newDocument:), menu commands
├── MarkdownDocument.swift      — FileDocument + UTType.markdown (read+write)
├── ContentView.swift           — Toolbar Picker + ZStack(content, FindBar)
│                                 switches Preview / Split / Source via @SceneStorage
├── ViewMode.swift              — enum Preview / Split / Source + cycle helper
├── WebView.swift               — NS/UIViewRepresentable around WKWebView
│                                 (Coordinator owns FileWatcher + observers)
├── MarkdownEditor.swift        — NS/UITextView wrapper with NSTextStorage syntax
│                                 highlighting (regex-based) + native undo/redo,
│                                 shared Highlighter + Palette across macOS/iOS
├── LineNumberRulerView.swift   — NSRulerView subclass attached as the editor's
│                                 verticalRulerView. macOS only (#if os(macOS)).
│                                 Soft-wrap-aware: only paragraph starts get a number.
├── FindBar.swift               — SwiftUI floating find bar (NSSearchField-like)
├── FileWatcher.swift           — DispatchSource-based live reload (macOS only)
└── HelpWindows.swift           — internal Help / What's New / About windows
                                  (macOS only). Help & What's New fetch live
                                  from GitHub raw / API and render through the
                                  same WebView pipeline as documents. About is
                                  a custom replacement for the system panel
                                  that includes a "View on GitHub" button.

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

### Editor mode (v0.2)
1. `DocumentGroup(newDocument: MarkdownDocument())` enables full editing — `Cmd+S`, dirty indicator (dot in close button), and auto-save on window resign-key are inherited from `NSDocument` plumbing
2. `ContentView` exposes a 3-way `Picker` (Preview / Split / Source) bound to `@SceneStorage("viewMode")` so the choice persists per window
3. **Source** mode mounts `MarkdownEditor` (NSTextView wrapper) bound to `$document.text`; edits propagate via the SwiftUI binding
4. **Split** mode wraps both panes in `HSplitView` — the divider is draggable, each pane has `minWidth: 240`
5. **Preview** mode keeps the original `WebView` — typing in the editor re-renders the preview in the next SwiftUI pass
6. Syntax highlighting in the editor is implemented via `NSTextStorage` attribute spans, recomputed on every `textDidChange` via a small set of regex (headings, bold, italic, inline code, fenced code, links, blockquotes, list markers)
7. Native undo/redo comes for free with `NSTextView.allowsUndo = true`
8. `Cmd+/` posts `.toggleViewMode` which cycles Preview → Split → Source → Preview

### Line numbers gutter (v0.5, macOS only)
1. `MarkdownEditor.makeNSView` instantiates `LineNumberRulerView(textView:scrollView:)`, attaches it as `scroll.verticalRulerView` and sets `hasVerticalRuler = true`, `rulersVisible = true`. AppKit takes over scroll synchronisation, line-wrapping awareness and clipping for free — same plumbing Xcode's gutter uses.
2. Width is recomputed on every `NSText.didChangeNotification` from `ceil(log10(lineCount + 1))` digits + horizontal padding (minimum 28 pt). When it changes by more than 0.5 pt the ruler calls `invalidateHashMarks()` so AppKit re-lays it out without flicker.
3. Three observers keep the ruler in sync: `NSText.didChangeNotification` (text edits), `boundsDidChangeNotification` on the clip view (scroll), `frameDidChangeNotification` on the text view (window resize).
4. `drawHashMarksAndLabels(in:)` walks the visible glyph range with `layoutManager.enumerateLineFragments(forGlyphRange:)`. A fragment receives a number only when the character at its location is at the document start or right after a `\n` — soft-wrap continuations are skipped (Xcode / VS Code convention).
5. Two edge cases are explicitly handled: an empty document still draws `"1"` at the top, and a document ending with `\n` numbers the trailing empty line via `layoutManager.extraLineFragmentRect`.
6. The Coordinator keeps a `weak ruler` so `updateNSView` can call `ruler?.needsDisplay = true` when the document text is replaced from outside (live-reload).

### Auto-update via Sparkle 2 (v0.6, macOS only)
1. `MarkdownViewerApp` instantiates an `SPUStandardUpdaterController(startingUpdater: true, …)`. Sparkle starts polling on launch and on a 24-hour schedule (`SUEnableAutomaticChecks` + `SUScheduledCheckInterval: 86400` in `Info.plist`).
2. Sparkle reads `SUFeedURL` from `Info.plist` (= `https://raw.githubusercontent.com/vincentlauriat/MarkdownViewer/main/appcast.xml`) and downloads the appcast.
3. Each item in the appcast is signed with an EdDSA signature (`sparkle:edSignature` attribute on `<enclosure>`). Sparkle verifies the signature against the public key embedded in `Info.plist` (`SUPublicEDKey`) before accepting any update — this is in addition to the Apple Developer ID + notarization checks.
4. If the appcast lists a higher `<sparkle:version>` than the running `CFBundleShortVersionString`, Sparkle's UI offers **Install and Relaunch** / **Remind Me Later** / **Skip This Version**. On install, Sparkle downloads the DMG, mounts it, validates the signature, swaps the running `.app`, and relaunches the new version — entirely automatic, no user drag-and-drop.
5. The **MarkdownViewer → Check for Updates…** menu item calls `updaterController.checkForUpdates(nil)` which forces a non-silent check (shows a result even when the app is up to date).
6. The pipeline producing published DMGs is `Scripts/release.sh <version>`. After Apple notarization + stapling, it auto-fetches Sparkle 2's `sign_update` tool (cached in `.sparkle-tools/`, gitignored), uses the EdDSA private key from the macOS keychain (account "MarkdownViewer", set up once via `generate_keys`) to sign the DMG, then writes / overwrites the repo-root `appcast.xml` with the new entry. The script prints the two suggested commands (`gh release create` + `git add appcast.xml && commit && push`) — it never pushes on its own.

### Internal Help / What's New / About windows (v0.6, macOS only)
1. **Help** (`⌘?`) — `HelpWindowView` fetches `https://raw.githubusercontent.com/vincentlauriat/MarkdownViewer/main/README.md` via URLSession, then feeds the markdown to the same `WebView` pipeline used for documents. A footer button opens the GitHub README page in Safari.
2. **What's New** — `WhatsNewWindowView` queries `https://api.github.com/repos/vincentlauriat/MarkdownViewer/releases`, decodes the JSON, and concatenates each release's `body` markdown into a single document with `## tag_name` + date headers, rendered the same way.
3. **About** — `AboutWindowView` replaces the standard SwiftUI About panel via `CommandGroup(replacing: .appInfo)`. Shows the app icon (96×96), name, version + build (read from `CFBundleShortVersionString` and `CFBundleVersion`), description, **View on GitHub** button, and copyright. `windowResizability(.contentSize)` keeps the window non-resizable, mimicking the system About panel.
4. All three windows are exposed through SwiftUI `Window` scenes with stable `id`s (`"about"`, `"help"`, `"whats-new"`); the menu items use `@Environment(\.openWindow)` to open them.
5. **Pitfall avoided**: a `View` extension that wrapped `self` in its body caused infinite recursion (`KERN_PROTECTION_FAILURE` stack overflow). Always use a sibling subview (here `FooterBar`), not an extension that re-emits the calling view.

### YAML frontmatter toggle (v0.2.x)
1. `render.js` runs `extractFrontmatter(text)` against `^---\n…\n---\n` at the start of the source. The captured YAML is rendered in a styled `<aside class="frontmatter">` above the main content; the body is parsed by markdown-it as usual.
2. `body.hide-frontmatter` (CSS) hides the aside without removing it from the DOM. `window.setFrontmatterVisible(bool)` toggles the class.
3. `ContentView` exposes a toolbar `Button` (`tag` / `tag.fill`, shortcut `⇧⌘Y`) bound to `@SceneStorage("showFrontmatter")` (default: `false` — hidden, à la Obsidian)
4. The button is `.disabled(!hasFrontmatter)` — Swift parses the first lines for `---` … `---` so the UI stays accurate without a JS round-trip
5. The visibility state is re-applied on every `flush()` from `WebView.Coordinator`, so live-reloading the file does not reset the toggle
6. `highlight.js` is invoked explicitly on the YAML `<code class="language-yaml">` block (markdown-it's `highlight` callback only fires on Markdown-parsed code fences, not on HTML we inject ourselves)

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
