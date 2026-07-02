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
├── MarkdownViewerApp.swift     — @main, DocumentGroup(newDocument:), commandes menu
├── MarkdownDocument.swift      — FileDocument + UTType.markdown (read+write)
├── ContentView.swift           — Toolbar Picker + Button frontmatter + ZStack(content, FindBar)
│                                 switch Preview / Split / Source via @SceneStorage
├── ViewMode.swift              — enum Preview / Split / Source + helper cycle
├── WebView.swift               — NS/UIViewRepresentable autour de WKWebView
│                                 (Coordinator possède FileWatcher + observers)
├── MarkdownEditor.swift        — wrapper NS/UITextView avec syntax highlighting
│                                 via NSTextStorage (regex) + undo/redo natif,
│                                 Highlighter + Palette partagés macOS/iOS
├── LineNumberRulerView.swift   — sous-classe NSRulerView attachée comme
│                                 verticalRulerView de l'éditeur. macOS uniquement
│                                 (#if os(macOS)). Soft-wrap-aware : seul le 1er
│                                 fragment de chaque paragraphe reçoit un numéro.
├── FindBar.swift               — find bar SwiftUI flottante (à la NSSearchField)
├── FileWatcher.swift           — live reload basé sur DispatchSource (macOS uniquement)
└── HelpWindows.swift           — fenêtres internes Help / What's New / About
                                  (macOS uniquement). Help & What's New
                                  fetchent en live depuis GitHub raw / API et
                                  rendent via le même pipeline WebView que les
                                  documents. About remplace le panel système
                                  pour exposer un bouton "View on GitHub".

MarkdownViewer/Resources/
└── web/
    ├── index.html            — page hôte
    ├── render.js             — pipeline markdown-it + highlight.js + KaTeX + Mermaid + frontmatter
    └── vendor/               — libs tierces épinglées (téléchargées par Scripts/fetch-vendor.sh)

MarkdownViewerQL/                — extension Quick Look (macOS, v0.8)
├── Sources/
│   └── PreviewViewController.swift — QLPreviewingController + WKWebView, réutilise
│                                     le même pipeline web/ bundlé que l'app
└── MarkdownViewerQL.entitlements  — app-sandbox + read-only user-selected
                                     (seule cible sandboxée)
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

### Gutter de numéros de ligne (v0.5, macOS uniquement)
1. `MarkdownEditor.makeNSView` instancie `LineNumberRulerView(textView:scrollView:)`, l'attache à `scroll.verticalRulerView` et active `hasVerticalRuler = true`, `rulersVisible = true`. AppKit prend en charge la synchro de scroll, la prise en compte du wrapping et le clipping nativement — exactement la même plomberie que la gutter de Xcode.
2. La largeur est recalculée à chaque `NSText.didChangeNotification` à partir de `ceil(log10(lineCount + 1))` digits + padding horizontal (minimum 28 pt). Quand elle change de plus de 0.5 pt, le ruler appelle `invalidateHashMarks()` pour qu'AppKit re-layout sans flicker.
3. Trois observers maintiennent le ruler en cohérence : `NSText.didChangeNotification` (édition), `boundsDidChangeNotification` sur le clip view (scroll), `frameDidChangeNotification` sur le text view (resize de fenêtre).
4. `drawHashMarksAndLabels(in:)` parcourt la range de glyphs visibles via `layoutManager.enumerateLineFragments(forGlyphRange:)`. Un fragment reçoit un numéro uniquement si le caractère à sa position est en début de document ou juste après un `\n` — les continuations soft-wrap sont skip (convention Xcode / VS Code).
5. Deux edge cases gérés explicitement : un document vide affiche quand même `"1"` en haut, et un document terminé par `\n` numérote la dernière ligne vide via `layoutManager.extraLineFragmentRect`.
6. Le Coordinator garde un `weak ruler` pour que `updateNSView` puisse appeler `ruler?.needsDisplay = true` quand le texte est remplacé depuis l'extérieur (live-reload).

### Auto-update via Sparkle 2 (v0.6, macOS uniquement)
1. `MarkdownViewerApp` instancie un `SPUStandardUpdaterController(startingUpdater: true, …)`. Sparkle commence à poller au démarrage et selon un schedule de 24h (`SUEnableAutomaticChecks` + `SUScheduledCheckInterval: 86400` dans `Info.plist`). Depuis v0.6.2, Sparkle **ne télécharge jamais silencieusement** : `automaticallyDownloadsUpdates = false` (plus `SUAutomaticallyUpdate: false` en garde-fou plist) — l'utilisateur voit toujours un prompt avant tout download/install. Introduit après qu'un install silencieux en arrière-plan contre notre DMG à layout custom a échoué et tué l'app en cours d'usage.
2. Sparkle lit `SUFeedURL` depuis `Info.plist` (= `https://raw.githubusercontent.com/vincentlauriat/MarkdownViewer/main/appcast.xml`) et télécharge l'appcast.
3. Chaque item de l'appcast est signé avec une signature EdDSA (attribut `sparkle:edSignature` sur `<enclosure>`). Sparkle vérifie la signature contre la clé publique embarquée dans `Info.plist` (`SUPublicEDKey`) avant d'accepter une mise à jour — en plus des vérifications Apple Developer ID + notarization.
4. Si l'appcast liste une `<sparkle:version>` plus haute que le **`CFBundleVersion`** de l'app courante (un build number entier, bumpé à chaque release — *pas* la version marketing ; depuis v0.7 `release.sh` lit le vrai build number via PlistBuddy, suite à un bug de comparaison où `0.7.0` était jugée plus ancienne que le build `1`), l'UI Sparkle propose **Install and Relaunch** / **Remind Me Later** / **Skip This Version**. À l'install, Sparkle télécharge le DMG, le monte, valide la signature, swap le `.app` courant, et relance la nouvelle version — entièrement automatique, sans drag-and-drop utilisateur.
5. L'entrée menu **MarkdownViewer → Check for Updates…** appelle `updaterController.checkForUpdates(nil)` qui force un check non-silent (affiche un résultat même si l'app est à jour).
6. Le pipeline qui produit les DMG publiés est `Scripts/release.sh <version>`. Après notarization Apple + stapling, il auto-fetch le `sign_update` de Sparkle 2 (caché dans `.sparkle-tools/`, gitignored), utilise la clé privée EdDSA depuis le keychain macOS (account "MarkdownViewer", générée une fois via `generate_keys`) pour signer le DMG, puis écrit / écrase le `appcast.xml` à la racine du repo avec la nouvelle entrée. Le script imprime les deux commandes suggérées (`gh release create` + `git add appcast.xml && commit && push`) — il ne push jamais tout seul.
7. **La paire EdDSA ne doit jamais être régénérée.** La clé publique est embarquée dans chaque `Info.plist` livré ; régénérer la paire casse silencieusement l'auto-update pour toutes les installs existantes (elles rejettent la nouvelle signature). C'est arrivé une fois : la clé d'origine (v0.6 → v0.8.0) a été écrasée sans backup, forçant une rotation assumée avec v0.8.1 — les utilisateurs ≤ v0.8.0 ont dû télécharger cette release manuellement. La clé publique active est `9PD2SBwLL4XoycyAGzaE+gO7ctuxSfuFMMajiZdXhXQ=` ; `release.sh` porte un bloc d'avertissement « DO NOT REGENERATE », et la clé privée doit être exportée une fois (`generate_keys -x`) vers un backup hors keychain.

### Zoom du contenu et highlight de la ligne courante (v0.7, macOS uniquement)
1. **Zoom** — `ContentView` détient `@SceneStorage("zoomRatio")` (Double, défaut 1.0). `Cmd+` / `Cmd-` / `Cmd0` postent `.zoomIn` / `.zoomOut` / `.zoomReset` ; les receivers SwiftUI clampent la valeur dans `[0.5, 3.0]` avec un step de 0.1 et la persistent dans la scene storage. `WebView` déclare `var zoom: Double = 1.0` ; `updateNSView` applique `webView.pageZoom = CGFloat(zoom)` uniquement quand la valeur a changé (évite un relayout inutile). Sur iOS la prop existe mais est ignorée — `WKWebView.pageZoom` est macOS-only.
2. **Highlight ligne courante** — `LineNumberRulerView` ajoute un `currentLineNumber: Int` et un `var highlightCurrentLine: Bool = true`. Un nouvel observer sur `NSTextView.didChangeSelectionNotification` recalcule la ligne en comptant les `\n` avant `selectedRange().location` ; le ruler court-circuite le redraw quand la ligne n'a pas changé. `drawNumber(_:atTextContainerY:textView:attrs:)` utilise un style semibold + `controlAccentColor` pour le numéro courant, fallback gris tertiaire sinon.
3. **Plumbing** — `MarkdownEditor` expose `var highlightCurrentLine: Bool = true` et le pousse au ruler dans `makeNSView` (initial) et `updateNSView` (quand le binding bascule). `ContentView` garde `@SceneStorage("highlightCurrentLine")` et le toggle via `.toggleCurrentLineHighlight`, posté depuis un menu item *View*.

### Fenêtres internes Help / What's New / About (v0.6, macOS uniquement)
1. **Help** (`⌘?`) — `HelpWindowView` fetch `https://raw.githubusercontent.com/vincentlauriat/MarkdownViewer/main/README.md` via URLSession, puis injecte le markdown dans le même pipeline `WebView` que les documents. Un bouton footer ouvre la page README sur GitHub dans Safari.
2. **What's New** — `WhatsNewWindowView` interroge `https://api.github.com/repos/vincentlauriat/MarkdownViewer/releases/latest` (depuis v0.8 : objet release unique au lieu de la liste complète), et rend un seul bloc markdown `# titre` + date + body de la même façon. Le lien « View all releases on GitHub » du footer donne accès à l'historique complet.
3. **About** — `AboutWindowView` remplace le panel About SwiftUI standard via `CommandGroup(replacing: .appInfo)`. Affiche l'icône (96×96), le nom, version + build (lus depuis `CFBundleShortVersionString` et `CFBundleVersion`), description, bouton **View on GitHub**, et copyright. `windowResizability(.contentSize)` empêche le resize, mimicking le panel About système.
4. Les trois fenêtres sont exposées via des scenes SwiftUI `Window` avec des `id` stables (`"about"`, `"help"`, `"whats-new"`) ; les menu items utilisent `@Environment(\.openWindow)` pour les ouvrir.
5. **Piège évité** : une extension `View` qui wrappait `self` dans son body causait une récursion infinie (`KERN_PROTECTION_FAILURE` stack overflow). Toujours utiliser une sub-view sibling (ici `FooterBar`), pas une extension qui ré-émet la calling view.

### Toggle frontmatter YAML (v0.2.x)
1. `render.js` exécute `extractFrontmatter(text)` contre `^---\n…\n---\n` au début de la source. Le YAML capturé est rendu dans un `<aside class="frontmatter">` stylisé au-dessus du contenu principal ; le body est parsé par markdown-it normalement
2. `body.hide-frontmatter` (CSS) masque l'aside sans le retirer du DOM. `window.setFrontmatterVisible(bool)` toggle la classe
3. `ContentView` expose un `Button` toolbar (`tag` / `tag.fill`, raccourci `⇧⌘Y`) lié à `@SceneStorage("showFrontmatter")` (default : `false` — masqué, à la Obsidian)
4. Le bouton est `.disabled(!hasFrontmatter)` — Swift parse les premières lignes pour `---` … `---` afin que l'UI reste cohérente sans round-trip JS
5. L'état de visibilité est ré-appliqué à chaque `flush()` du `WebView.Coordinator`, donc le live-reload n'efface pas le toggle
6. `highlight.js` est invoqué explicitement sur le bloc YAML `<code class="language-yaml">` (le callback `highlight` de markdown-it ne se déclenche que sur les fences Markdown parsées, pas sur le HTML qu'on injecte nous-mêmes)

### Extension Quick Look (v0.8, macOS uniquement)
1. `MarkdownViewerQL` est une cible app-extension (extension point `com.apple.quicklook-preview`) embarquée dans `MarkdownViewer.app/Contents/PlugIns/` — `embed: true, link: false` dans `project.yml`.
2. `PreviewViewController: QLPreviewingController` reçoit l'URL du fichier depuis Quick Look, lit le markdown, charge le **même dossier `web/` bundlé** (compilé dans le bundle propre de l'extension) dans un `WKWebView`, et injecte `window.renderMarkdown(...)` exactement comme le main app — la preview barre d'espace bénéficie gratuitement de la coloration, KaTeX, Mermaid et du dark mode.
3. `QLSupportedContentTypes: [net.daringfireball.markdown]`. Contrairement au main app, l'extension **est sandboxée** (entitlements `app-sandbox` + `files.user-selected.read-only`) — requis pour les process d'extension.
4. `release.sh` signe le `.appex` en Developer ID avant de signer l'app hôte. La validation runtime exige une vraie identité de signature : en ad-hoc, le process d'extension crashe à l'enregistrement XPC (team ID nil), donc Quick Look ne fonctionne que sur les builds signés Developer ID.

### Workaround crash CoreAnimation half-float (v0.8.1, macOS uniquement)
1. **Symptôme** : `SIGABRT` côté système dans QuartzCore pendant le scroll d'un document (surtout visible en mode Split) sur Apple Silicon M4 — `Function image_rect_blit_frag_lph was not found in the library`. La fonction manquante est le variant **half-float / EDR** du shader de blit de CoreAnimation ; reproduit sur macOS 26.5.1 (release) et 27.0 (beta). Aucune frame MarkdownViewer dans la pile fautive : le défaut est dans l'OS (remonté à Apple, voir `docs/apple-feedback-coreanimation-crash.md`).
2. **Mitigation couche 1 — WebView opaque** : `drawsBackground=false` retiré, `underPageBackgroundColor` posé selon le thème, et `index.html` utilise des fonds solides thématisés (`#ffffff` / `#0d1117`) pour que le compositing utilise un blit copie simple au lieu de l'alpha blending.
3. **Mitigation couche 2 — épinglage sRGB 8-bit** (celle qui a marché) : `pinSRGBColorSpace()` pose `window.colorSpace = .sRGB` et le `contentsFormat = .RGBA8Uint` de la layer, routant CoreAnimation vers les shaders 8-bit standard qui existent. Inconvénient : la fenêtre rend sans wide-gamut/EDR — sans importance pour un lecteur markdown.

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
- **Code partagé avec l'extension QL par copie, pas par module** : `encodeForJS`, la logique de thème et le chargement du bundle web sont dupliqués entre `WebView.swift` et `PreviewViewController.swift`, et le dossier `web/` entier est compilé dans les deux bundles. Acceptable à la taille actuelle ; un framework/package partagé se justifiera si un troisième consommateur apparaît.
- **`sparkle:version` = `CFBundleVersion`** : Sparkle compare des build numbers, pas des versions marketing. Chaque release doit bumper `CFBundleVersion` (entier) dans `project.yml` sur les trois cibles, sinon les installs plus anciennes se croiront à jour.
