# Architecture — MarkdownViewer

> Cette version FR est maintenue en miroir de [`ARCHITECTURE_EN.md`](./ARCHITECTURE_EN.md).
> En cas d'écart, la version anglaise fait foi.

## Vue d'ensemble

```
┌─────────────────────────────────────────────────┐
│                   macOS Finder                  │
│         (double-clic sur fichier .md)           │
└─────────────────────┬───────────────────────────┘
                      │ Launch Services
                      ▼
┌─────────────────────────────────────────────────┐
│      MarkdownViewer.app  (SwiftUI + AppKit)     │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │            DocumentGroup                │    │
│  │     (multi-fenêtres, Open Recent,       │    │
│  │      auto-save, dirty indicator)        │    │
│  └─────────────────┬───────────────────────┘    │
│                    │                            │
│  ┌─────────────────▼───────────────────────┐    │
│  │      MarkdownDocument: FileDocument     │    │
│  │   readableContentTypes = [.markdown]    │    │
│  └─────────────────┬───────────────────────┘    │
│                    │                            │
│  ┌─────────────────▼───────────────────────┐    │
│  │   ContentView ⊕ FindBar / Toolbar       │    │
│  │   switch viewMode (Preview/Split/Source)│    │
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
│  │                                         │    │
│  │   MarkdownEditor (NSViewRepresentable)  │    │
│  │   ┌──────────┐  highlight via           │    │
│  │   │NSTextView│  NSTextStorage           │    │
│  │   └──────────┘                          │    │
│  └─────────────────────────────────────────┘    │
└──────────────────────┬──────────────────────────┘
                       │ evaluateJavaScript
                       ▼
┌─────────────────────────────────────────────────┐
│   Resources/web/  (bundled, file://)            │
│   ├── index.html                                │
│   ├── render.js                                 │
│   └── vendor/                                   │
│       ├── markdown-it · markdown-it-task-lists  │
│       ├── highlight.js + thèmes GitHub          │
│       ├── katex + auto-render + fonts           │
│       ├── mermaid                               │
│       ├── dompurify                             │
│       └── github-markdown.css                   │
└─────────────────────────────────────────────────┘
```

## Pile technique

| Couche | Choix | Raison |
|---|---|---|
| Langage | Swift 5.9+ | Natif macOS, futur iOS / iPadOS |
| UI | SwiftUI | Cross-platform Apple, multi-fenêtres simple |
| Document model | `DocumentGroup` + `FileDocument` | File association native, Open Recent, save / dirty indicator gratuits |
| Hôte de rendu | `WKWebView` via `NSViewRepresentable` | Permet de réutiliser l'écosystème JS Markdown |
| Éditeur | `NSTextView` via `NSViewRepresentable` | Undo/Redo natif, find natif, attributes via `NSTextStorage` |
| Parser MD | `markdown-it` 14 | CommonMark + GFM, plugin-friendly |
| Coloration code | `highlight.js` 11 | Léger (~100 KB), thèmes GitHub light/dark |
| Math | `KaTeX` 0.16 | Qualité serveur, rapide |
| Diagrammes | `Mermaid` 10 | Standard de fait |
| Sanitisation | `DOMPurify` 3 | Défense en profondeur au-dessus de `html: false` |
| Style | `github-markdown-css` 5 | Look familier, light + dark |
| File watching | `DispatchSource.makeFileSystemObjectSource` | Bas niveau, robuste, debouncé |
| Project file | `XcodeGen` | Source de vérité YAML, pas de douleur de merge `.pbxproj` |

## Modules Swift

```
MarkdownViewer/Sources/
├── MarkdownViewerApp.swift   — @main, DocumentGroup(newDocument:), commandes menu
├── MarkdownDocument.swift    — FileDocument + UTType.markdown (read+write)
├── ContentView.swift         — Toolbar Picker + Button frontmatter + ZStack(content, FindBar)
│                               switch Preview / Split / Source via @SceneStorage
├── ViewMode.swift            — enum Preview / Split / Source + helper cycle
├── WebView.swift             — NSViewRepresentable autour de WKWebView
│                               (Coordinator possède FileWatcher + observers)
├── MarkdownEditor.swift      — wrapper NSTextView avec syntax highlighting
│                               via NSTextStorage (regex) + undo/redo natif
├── FindBar.swift             — find bar SwiftUI flottante (à la NSSearchField)
└── FileWatcher.swift         — live reload basé sur DispatchSource

MarkdownViewer/Resources/
└── web/
    ├── index.html            — page hôte
    ├── render.js             — pipeline markdown-it + highlight.js + KaTeX + Mermaid + frontmatter
    └── vendor/               — libs tierces épinglées (téléchargées par Scripts/fetch-vendor.sh)
```

## Flux de données

### Ouverture d'un fichier
1. Finder → Launch Services → `MarkdownViewer.app`
2. `DocumentGroup` instancie un `MarkdownDocument` (lit en UTF-8)
3. `ContentView` rend `WebView(markdown: document.text)` plus l'overlay `FindBar` optionnel et la toolbar
4. `WebView.makeNSView` construit un `WKWebView` et appelle `loadFileURL(index.html, allowingReadAccessTo: web/)`
5. Sur `webView(_:didFinish:)`, le Coordinator injecte `window.renderMarkdown(<json string>)`
6. `render.js` parse le Markdown, colorise le code via `highlight.js`, rend les math via KaTeX, remplace les blocs ` ```mermaid ` par des diagrammes Mermaid

### Live reload
1. Le Coordinator récupère `webView.window?.representedURL` (posée par `DocumentGroup` une fois la fenêtre attachée)
2. `FileWatcher` ouvre un fd `O_EVTONLY` et un `DispatchSource` avec mask `[.write, .delete, .rename, .extend]`
3. Sur tout événement, le change est debouncé 120 ms, le fichier relu et `renderMarkdown(...)` ré-injecté
4. Sur `.delete` / `.rename` (atomic save : vim, VS Code), le watcher ferme l'ancien fd et en ouvre un nouveau sur le même path avant de reload
5. Latence mesurée : ≈130 ms entre la modif disque et le re-render

### Dark mode
- KVO sur `NSApp.effectiveAppearance`
- Sur changement, `webView.evaluateJavaScript("window.setTheme('dark' | 'light')")`
- `setTheme()` toggle `body[data-theme]`, switch la stylesheet `highlight.js` active, et ré-initialise Mermaid avec le thème correspondant

### Find
1. `Cmd+F` (commande menu) poste `.toggleFindBar` → `ContentView` affiche l'overlay avec `@FocusState`
2. Le typing poste `.findRequest(query, forward: true)` à chaque keystroke
3. `Cmd+G` / `Cmd+Shift+G` postent `.findNext` / `.findPrevious` (réutilisent la dernière query)
4. Le Coordinator filtre par `webView.window?.isKeyWindow` pour que les fenêtres inactives restent muettes, puis appelle `WKWebView.find(_:configuration:)` (natif macOS 12+)

### Mode édition (v0.2)
1. `DocumentGroup(newDocument: MarkdownDocument())` active toute l'édition — `Cmd+S`, dirty indicator (point dans close button) et auto-save sur perte de focus sont hérités de la plomberie `NSDocument`
2. `ContentView` expose un `Picker` 3 voies (Preview / Split / Source) lié à `@SceneStorage("viewMode")` — la sélection persiste par fenêtre
3. **Source** : monte `MarkdownEditor` (wrapper NSTextView) lié à `$document.text` ; les éditions se propagent via le binding SwiftUI
4. **Split** : wrap les deux panneaux dans `HSplitView` — divider draggable, chaque pane a `minWidth: 240`
5. **Preview** : garde le `WebView` original — taper dans l'éditeur re-rend la preview au tour suivant SwiftUI
6. Le syntax highlighting de l'éditeur est implémenté via spans d'attributs sur `NSTextStorage`, recompilé sur chaque `textDidChange` via un petit set de regex (titres, gras, italique, code inline, fenced code, liens, citations, marqueurs de listes)
7. Undo / Redo natif via `NSTextView.allowsUndo = true`
8. `Cmd+/` poste `.toggleViewMode` qui cycle Preview → Split → Source → Preview

### Toggle frontmatter YAML (v0.2.x)
1. `render.js` exécute `extractFrontmatter(text)` contre `^---\n…\n---\n` au début de la source. Le YAML capturé est rendu dans un `<aside class="frontmatter">` stylisé au-dessus du contenu principal ; le body est parsé par markdown-it normalement
2. `body.hide-frontmatter` (CSS) masque l'aside sans le retirer du DOM. `window.setFrontmatterVisible(bool)` toggle la classe
3. `ContentView` expose un `Button` toolbar (`tag` / `tag.fill`, raccourci `⇧⌘Y`) lié à `@SceneStorage("showFrontmatter")` (default : `false` — masqué, à la Obsidian)
4. Le bouton est `.disabled(!hasFrontmatter)` — Swift parse les premières lignes pour `---` … `---` afin que l'UI reste cohérente sans round-trip JS
5. L'état de visibilité est ré-appliqué à chaque `flush()` du `WebView.Coordinator`, donc le live-reload n'efface pas le toggle
6. `highlight.js` est invoqué explicitement sur le bloc YAML `<code class="language-yaml">` (le callback `highlight` de markdown-it ne se déclenche que sur les fences Markdown parsées, pas sur le HTML qu'on injecte nous-mêmes)

### Print / Export PDF
1. `Cmd+P` (commande menu) poste `.printActiveDocument`
2. Le Coordinator construit un `NSPrintInfo`, demande à `webView.printOperation(with:)` un `NSPrintOperation`, le run modal contre la fenêtre active
3. La dialog d'impression macOS native gère "Save as PDF" via le menu PDF standard — pas de code en plus

## Points d'attention

- **Sécurité `WKWebView`** : JavaScript activé, `markdown-it` tourne avec `html: false`, et DOMPurify wrap la sortie avant injection — aucun HTML non-fiable n'atteint le DOM. Navigation interceptée dans `decidePolicyFor` : les clics de liens externes ouvrent via `NSWorkspace.shared.open`, tout le reste est refusé.
- **Images locales relatives** : à résoudre par rapport au dossier parent du fichier. Actuellement délégué au `WKWebView` puisque l'app n'est pas sandboxée ; si le sandbox est activé plus tard, un security-scoped bookmark sur le dossier parent est requis et `loadFileURL(_:allowingReadAccessTo:)` doit être ré-appliqué.
- **Gros fichiers** : au-dessus de ~500 KB le rendu Markdown commence à ramer. Un renderer progressif (chunks, intersection observer) est la bonne piste mais hors v1.
- **Cross-platform** : garder les imports `AppKit` hors de la couche modèle. `MarkdownDocument` et `FileWatcher` sont déjà AppKit-free ; le port iOS demande surtout un wrapper `WebView` UIKit-flavoured et un `FindBar` redesigné pour les compact width classes.
- **`resources:` dans XcodeGen** : il n'y a *pas* de clé top-level `resources:`. Les ressources vont dans `sources:` avec `buildPhase: resources`. Mal configurer ça produit un `.app` sans `Contents/Resources/` (sans erreur).
- **Swift 6 concurrency + `NotificationCenter`** : la closure passée à `addObserver` n'hérite *pas* du `@MainActor` du contexte appelant. Le helper `observe(_:action:)` type son paramètre `@escaping @MainActor @Sendable (Notification) -> Void` pour que l'inférence se propage aux call sites sans `@MainActor in` partout.
- **`actool` thinning sur Xcode 26** : produit un `AppIcon.icns` à 4 tailles seulement. Workaround : `postCompileScripts` dans `project.yml` qui rebuild le `.icns` via `iconutil` après `actool`. Voir `Scripts/make-icon.swift` pour la génération source.
