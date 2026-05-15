# TODOS — MarkdownViewer

Legend: `[ ]` to do · `[~]` in progress · `[x]` done · `[-]` cancelled

## v1 — Viewer MVP

### Must-have
- [x] Bootstrap a SwiftUI Xcode project (target macOS 13+) — via XcodeGen
- [x] Wire `.md` / `.markdown` file association in `Info.plist` (`CFBundleDocumentTypes` + `UTImportedTypeDeclarations`)
- [x] `DocumentGroup` + `FileDocument` architecture — multi-window and Open Recent come for free
- [x] `WKWebView` embedded in a SwiftUI view via `NSViewRepresentable`
- [x] Local web bundle: `index.html` + markdown-it + highlight.js + KaTeX + Mermaid + DOMPurify + GitHub CSS
- [x] Render pipeline: Swift reads file → injects content via `evaluateJavaScript` → markdown-it parses → DOM rendered
- [x] Auto dark mode (CSS `prefers-color-scheme` + injected `data-theme` synced with `NSApp.effectiveAppearance`)
- [x] Native text selection / copy from `WKWebView`

### Validated features
- [x] Live reload: watch the file (`DispatchSource` on file descriptor) and refresh the preview
  - URL retrieved via `webView.window?.representedURL` (set by `DocumentGroup`, no need to migrate to `ReferenceFileDocument`)
  - 120 ms debounce, atomic-save handling (rename → re-bind on a fresh fd)
  - Measured latency: ~130 ms between disk change and re-render
- [x] Recent files: handled by `DocumentGroup` (verify at runtime)
- [x] Find in document: `Cmd+F` opens a floating SwiftUI `FindBar`, `Cmd+G` / `Cmd+Shift+G` for next/prev, Esc to dismiss — uses native `WKWebView.find(_:configuration:)`
- [x] Print / Export PDF: `Cmd+P` via native `WKWebView.printOperation` (the macOS print dialog's "Save as PDF" handles the export)

### v1 polish
- [ ] Stress-test on real files: large repo READMEs, 1 MB document, document with 100 images
- [ ] Verify minimal signing (Developer ID or self-signed for personal use)
- [x] Runtime test: open `sample.md`, verify rendering (math, code highlight, mermaid, dark mode) — visually validated
- [x] Migrate `NSLog` → `os.Logger` with subsystem `com.vincent.MarkdownViewer` (reliable observability through `log show`)
- [x] Install in `/Applications/MarkdownViewer.app` (Release build, ad-hoc signed)
- [x] Set as default `.md` handler via `duti` (also `markdown`, `mdown`, `mdwn`, `mkd`, `mkdn`, `public.plain-text`)

## v2 — Editing (shipped 2026-05-02, commit `7f77874`)

- [x] Toggle Preview / Source via segmented Picker in toolbar (`Cmd+/` cycles Preview → Split → Source)
- [x] Split mode (preview + source side by side) via `HSplitView` (draggable divider)
- [x] Native `MarkdownEditor` (NSTextView wrapper) with basic Markdown syntax highlighting through regex over `NSTextStorage` (headings, bold, italic, inline code, code blocks, links, blockquotes, list markers)
- [x] Save through `FileDocument` (native `Cmd+S` + auto-save on window resign-key, handled by DocumentGroup)
- [x] "Modified" indicator in the title bar (dot in the close button — standard `NSDocument` behaviour)
- [x] Native Undo / Redo via `NSTextView.allowsUndo = true`
- [x] CFBundleTypeRole: Viewer → Editor

## v3 — Multi-platform (Phases A–D shipped 2026-05-02, commit `039860a`)

- [x] **Phase A** — Cross-platform refactor of all sources (`#if os(macOS|iOS)`): WebView dual NS/UIViewRepresentable + shared Coordinator, MarkdownEditor NSTextView/UITextView wrappers + shared Highlighter + Palette, ContentView filters Split on iPhone + HSplitView→HStack, FindBar decoupled from AppKit
- [x] **Phase B** — Second target `MarkdownViewerIOS` in `project.yml` + `Info-iOS.plist` (UISupportsDocumentBrowser, LSSupportsOpeningDocumentsInPlace, UIFileSharingEnabled, iOS 16+, iPhone+iPad)
- [x] **Phase C** — Extended asset catalog: universal 1024×1024 iOS marketing icon, `Scripts/make-icon.swift` generates the iOS PNG
- [x] **Phase D** — `xcodebuild` iOS Simulator green (2026-05-02, after installing iOS 26.4.1 runtime ~8.5 GB via `xcodebuild -downloadPlatform iOS`). An iOS 16 fix in `FindBar.swift` (`.separator` shape style was iOS 17+, replaced by `#if`-guarded `Color(uiColor:.separator)` / `Color(nsColor:.separatorColor)` helpers). CLI build requires `CODE_SIGNING_ALLOWED=NO` due to the `com.apple.provenance` xattr on macOS Sequoia (Xcode IDE handles this correctly).
- [ ] **Phase E** — Runtime smoke test on iPad/iPhone Simulator from Xcode IDE (open a .md, test preview/split/source, find, print, auto dark mode, frontmatter toggle)
- [ ] **Phase F** — App Store distribution (signing, sandbox audit, review process) — deferred
- [ ] Test compatibility with Files.app + iCloud Drive — to be done in Phase E
- [ ] Live reload on iPadOS via `NSFilePresenter` — backlog post-v3, if there is demand

## v0.2.x — Polish

- [x] YAML frontmatter detection + toggle (Obsidian / Tolaria / Jekyll) — 🏷️ toolbar button, `⇧⌘Y` shortcut, persisted via `@SceneStorage`, disabled when no frontmatter is present

## v4 — Auto-update (macOS, from GitHub Releases)

- [x] **Mechanism chosen**: Sparkle 2 via SwiftPM — replaces the in-house UpdateChecker
- [ ] Semver comparison **numeric** (split on `.` then compare integers) — not String lexicographic, otherwise "1.10" < "1.9"
- [x] Release pipeline: **`Scripts/release.sh <version>`** (Release build + ad-hoc codesign via staging dir with `ditto --noextattr` to work around the `com.apple.provenance` xattr on macOS Sequoia + DMG via `hdiutil`). Prints the suggested `gh release create` command.
- [x] **First release `v0.3.0` published** on GitHub: https://github.com/vincentlauriat/MarkdownViewer/releases/tag/v0.3.0 (DMG 2.49 MB, ad-hoc signed). `releases/latest` API returns the release correctly.
- [ ] **Future migration to Sparkle**: replace UpdateChecker, add Sparkle SwiftPM, generate EdDSA key pair, configure `SUFeedURL` + `SUPublicEDKey` in Info.plist, release pipeline with `generate_appcast` + Apple Developer ID notarization — **deferred**
- [ ] **iOS / iPadOS**: not applicable outside App Store / TestFlight — macOS-only feature

## v0.5 — Editor polish (shipped 2026-05-04)

- [x] Line numbers gutter in the left margin of `MarkdownEditor`, Source + Split modes, **macOS only** — `NSRulerView` subclass, ~170 lines of Swift. Visually validated by Vincent on 2026-05-04 on `sample-long.md` (541 lines, 2→3 digit transition, soft-wrap, Source + Split modes, dark/light, undo)
- [x] **Notarized release pipeline (v0.5.1)** — Developer ID + Hardened Runtime + notarytool submit + stapler staple in `Scripts/release.sh`. No more Gatekeeper "right-click → Open" on notarized versions.

## v0.7 — Content zoom + current-line highlight (shipped 2026-05-05)

- [x] **F — Content zoom** (`⌘+` / `⌘-` / `⌘0`) — `WKWebView.pageZoom` driven by `@SceneStorage("zoomRatio")`, step 0.1, range [0.5, 3.0]. macOS only.
- [x] **D — Current-line highlight in gutter** — `LineNumberRulerView` observes `NSTextView` selection, renders the number in bold + `controlAccentColor`. Toggle via menu + `@SceneStorage`.
- [x] **G — Drag & drop `.md` onto the Dock icon** — free with `DocumentGroup`, visually validated by Vincent at runtime (2026-05-05).

## v0.6 — Sparkle auto-update + internal Help/What's New/About (shipped 2026-05-04)

- [x] **Sparkle 2** integrated via SwiftPM — replaces the in-house UpdateChecker. Modern UI, one-click Install-and-Relaunch, EdDSA signature on top of Apple notarization. `appcast.xml` hosted in `main` (raw.githubusercontent.com).
- [x] **Internal Help window** (`⌘?`) — fetches README from GitHub raw, rendered via the existing `WebView`, "View README on GitHub" button.
- [x] **Internal What's New window** — fetches `/releases` via GitHub API, concatenates release notes, rendered via WebView, "View all releases on GitHub" button.
- [x] **Custom About window** — `CommandGroup(replacing: .appInfo)` + `AboutWindowView` with icon, version, description, "View on GitHub" button, copyright. `windowResizability(.contentSize)`.
- [x] **`Scripts/release.sh`** extended — auto-fetches Sparkle CLI tools, signs each Sparkle.framework sub-binary, auto-generates `appcast.xml`.
- [x] **`UpdateChecker.swift` removed** — Sparkle handles everything.
- [x] **Bug fix** — stack overflow in `HelpWindows.swift` caused by a `View.footer` extension that wrapped `self`. Refactored into a `FooterBar` sibling struct.

## Backlog (post-v3)

- [ ] Quick Look extension (preview Markdown in Finder with the spacebar)
- [ ] CSS theme picker (GitHub light/dark, sepia, classic, custom)
- [ ] Floating / sidebar table of contents
- [x] Content zoom (`Cmd +/-`) — shipped v0.7.0
- [x] Drag & drop a `.md` onto the Dock icon (free with `DocumentGroup`, verified v0.7.0)
- [ ] App Store distribution (signing + sandbox + review process)
- [ ] Migrate `highlight.js` → Shiki if syntax-highlighting quality becomes a bottleneck
- [x] Init git repo + first commit + public GitHub repository: https://github.com/vincentlauriat/MarkdownViewer
- [x] Top-quality English README (badges, architecture diagram, tech stack, roadmap, contributing)
- [x] MIT LICENSE
