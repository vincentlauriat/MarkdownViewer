# Architecture — MarkdownViewer

## Vue d'ensemble

```
┌─────────────────────────────────────────────────┐
│                   macOS Finder                  │
│        (double-clic sur fichier .md)            │
└─────────────────────┬───────────────────────────┘
                      │ Launch Services
                      ▼
┌─────────────────────────────────────────────────┐
│      MarkdownViewer.app  (SwiftUI + AppKit)     │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │           DocumentGroup                 │    │
│  │   (multi-fenêtres, Open Recent, save)   │    │
│  └─────────────────┬───────────────────────┘    │
│                    │                            │
│  ┌─────────────────▼───────────────────────┐    │
│  │       MarkdownDocument: FileDocument    │    │
│  │   - readableContentTypes = [.md, .mdx]  │    │
│  │   - text: String                        │    │
│  └─────────────────┬───────────────────────┘    │
│                    │                            │
│  ┌─────────────────▼───────────────────────┐    │
│  │       PreviewView (SwiftUI)             │    │
│  │   contient WebView (NSViewRepresentable)│    │
│  └─────────────────┬───────────────────────┘    │
│                    │                            │
│  ┌─────────────────▼───────────────────────┐    │
│  │           WKWebView                     │    │
│  │   charge index.html bundlé localement   │    │
│  └─────────────────┬───────────────────────┘    │
└────────────────────┼────────────────────────────┘
                     │ evaluateJavaScript
                     ▼
┌─────────────────────────────────────────────────┐
│   Web bundle (Resources/web/)                   │
│   ├── index.html                                │
│   ├── markdown-it.min.js                        │
│   ├── shiki.min.js + thèmes/langs               │
│   ├── katex.min.js + katex.css                  │
│   ├── mermaid.min.js                            │
│   └── github-markdown.css                       │
└─────────────────────────────────────────────────┘
```

## Pile technique

| Couche | Choix | Raison |
|---|---|---|
| Langage | Swift 5.9+ | Natif macOS, futur iOS |
| UI | SwiftUI | Cross-platform Apple, multi-fenêtres simple |
| Document model | `DocumentGroup` + `FileDocument` | File association native, Open Recent gratuit, iCloud OK |
| Rendu | `WKWebView` via `NSViewRepresentable` | Permet libs JS riches, perf correcte |
| Parser MD | `markdown-it` (JS) | CommonMark + GFM, plugins (tables, checklists) |
| Coloration code | `shiki` (JS) | Thèmes VS Code, qualité supérieure à highlight.js |
| Math | `katex` (JS) | Rapide, rendu serveur-side possible |
| Diagrammes | `mermaid` (JS) | Standard de fait |
| Style | CSS GitHub-flavored | Familier, supporte light/dark |
| File watching | `DispatchSource.makeFileSystemObjectSource` | API bas niveau, robuste pour live reload |

## Modules Swift

```
MarkdownViewerApp.swift          (App entry, DocumentGroup)
  │
  ├─ MarkdownDocument.swift      (FileDocument, conformance read/write)
  ├─ ContentView.swift           (vue principale d'un document)
  │   └─ PreviewView.swift       (wrapper SwiftUI du WKWebView)
  │       └─ WebViewBridge.swift (NSViewRepresentable + WKScriptMessageHandler)
  ├─ MarkdownRenderer.swift      (sérialise le contenu vers JS payload)
  ├─ FileWatcher.swift           (DispatchSource pour live reload)
  └─ ExportService.swift         (Print / PDF via NSPrintOperation)

Resources/
  └─ web/                        (assets statiques bundlés)
      ├─ index.html
      ├─ render.js               (init markdown-it + Shiki + KaTeX + Mermaid)
      ├─ vendor/*.min.js
      └─ styles/github-markdown.css
```

## Flux de données

### Ouverture d'un fichier
1. Finder → Launch Services → MarkdownViewer.app
2. `DocumentGroup` instancie un `MarkdownDocument` (lit le fichier UTF-8)
3. `ContentView` rend `PreviewView(document: document)`
4. `WebViewBridge` charge `index.html` du bundle (URL `file://`)
5. Quand le `WKWebView` signale `didFinishNavigation`, on appelle `webView.evaluateJavaScript("renderMarkdown(\(escaped))")`
6. `render.js` parse + injecte dans le DOM, applique Shiki/KaTeX/Mermaid

### Live reload
1. `FileWatcher` ouvre un `DispatchSource` sur le file descriptor du fichier
2. Sur événement `.write` ou `.rename`, on relit le fichier et on rappelle `renderMarkdown(...)`
3. Debounce 100 ms pour éviter le double trigger des éditeurs (atomic save)

### Dark mode
- Observer `NSApp.effectiveAppearance` via KVO
- Sur changement, injecter `document.documentElement.dataset.theme = 'dark' | 'light'`
- CSS GitHub bascule via `[data-theme="dark"]`

## Points d'attention

- **Sécurité WKWebView** : `WKWebViewConfiguration.preferences.javaScriptEnabled = true` mais isoler dans un `WKContentWorld` pour éviter qu'un Markdown malveillant exploite quoi que ce soit. Désactiver navigation hors local.
- **Liens externes** : intercepter dans `decidePolicyForNavigationAction`, ouvrir avec `NSWorkspace.shared.open`.
- **Images locales relatives** : résoudre par rapport au dossier du fichier, autoriser via `loadFileURL(_:allowingReadAccessTo:)` sur le dossier parent.
- **Performance gros fichiers** : si > 500 ko, envisager rendu progressif (chunks). Hors v1.
- **Multi-plateforme** : éviter `AppKit` direct dans la logique métier ; isoler dans `#if os(macOS)`.
