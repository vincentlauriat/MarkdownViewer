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
- [ ] App icon (placeholder OK for now)
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

## v3 — Multi-platform

- [ ] iPadOS target — re-use `DocumentGroup` (already cross-platform)
- [ ] iOS target — adapt to compact width classes (toggle instead of split)
- [ ] Test compatibility with Files.app + iCloud Drive

## Backlog (post-v3)

- [ ] Quick Look extension (preview Markdown in Finder with the spacebar)
- [ ] CSS theme picker (GitHub light/dark, sepia, classic, custom)
- [ ] Floating / sidebar table of contents
- [ ] Content zoom (`Cmd +/-`)
- [ ] Drag & drop a `.md` onto the Dock icon (free with `DocumentGroup`, to verify)
- [ ] App Store distribution (signing + sandbox + review process)
- [ ] Migrate `highlight.js` → Shiki if syntax-highlighting quality becomes a bottleneck
- [x] Init git repo + first commit + public GitHub repository: https://github.com/vincentlauriat/MarkdownViewer
- [x] Top-quality English README (badges, architecture diagram, tech stack, roadmap, contributing)
- [x] MIT LICENSE
