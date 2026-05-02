# TODOS — MarkdownViewer

Légende : `[ ]` à faire · `[~]` en cours · `[x]` fait · `[-]` annulé

## v1 — MVP Viewer

### Indispensables
- [x] Initialiser le projet Xcode SwiftUI (cible macOS 13+) — via XcodeGen
- [x] Configurer file association `.md` / `.markdown` dans `Info.plist` (CFBundleDocumentTypes + UTImportedTypeDeclarations)
- [x] Architecture `DocumentGroup` + `FileDocument` pour multi-fenêtres et Open Recent gratuits
- [x] `WKWebView` intégré dans une vue SwiftUI (`NSViewRepresentable`)
- [x] Bundle web local : `index.html` + markdown-it + highlight.js + KaTeX + Mermaid + DOMPurify + CSS GitHub
- [x] Pipeline de rendu : Swift lit le fichier → injecte le contenu via `evaluateJavaScript` → markdown-it parse → DOM rendu
- [x] Support dark mode auto (CSS `prefers-color-scheme` + injection de `data-theme` synchro avec NSApp.effectiveAppearance)
- [x] Sélection / copier texte natif WKWebView

### Fonctionnalités validées
- [x] Live reload : observer le fichier (DispatchSource sur file descriptor) et rafraîchir le rendu
  - URL récupérée via `webView.window?.representedURL` (posée par DocumentGroup, pas besoin de `ReferenceFileDocument`)
  - Debounce 120 ms, gestion atomic save (rename → re-bind sur nouveau fd)
  - Latence mesurée : 130 ms entre modif disque et re-rendu
- [x] Recent files : géré par `DocumentGroup` (à vérifier au runtime)
- [x] Find in document : `Cmd+F` ouvre une `FindBar` SwiftUI flottante, `Cmd+G` / `Cmd+Shift+G` pour next/prev, Esc pour fermer — utilise `WKWebView.find(_:configuration:)` natif
- [x] Print / Export PDF : `Cmd+P` via `WKWebView.printOperation` natif (le bouton "Save as PDF" du dialog macOS gère l'export)

### Polish v1
- [x] App icon — "M↓" indigo squircle, généré par `Scripts/make-icon.swift` (10 tailles + Contents.json)
- [ ] Test sur fichiers de stress : README de gros repos, fichier de 1 Mo, doc avec 100 images
- [ ] Vérifier signing minimal (Developer ID ou self-signed pour usage perso)
- [x] Test runtime : ouvrir sample.md, vérifier rendu (math, code highlight, mermaid, dark mode) — validé visuellement « c'est super propre »
- [x] NSLog → `os.Logger` avec subsystem `com.vincent.MarkdownViewer` (observabilité fiable via `log show`)
- [x] Build Release + install dans `/Applications/MarkdownViewer.app` (4,4 Mo)
- [x] Définir l'app comme handler par défaut `.md` dans Finder via `duti` (couvre aussi `markdown`, `mdown`, `mdwn`, `mkd`, `mkdn`, `public.plain-text`)

## v2 — Édition (livrée 2026-05-02, commit `7f77874`)

- [x] Toggle Preview / Source via segmented Picker en toolbar (`Cmd+/` cycle Preview → Split → Source)
- [x] Mode split (preview + code côte à côte) via `HSplitView` (divider draggable)
- [x] Éditeur natif `MarkdownEditor` (NSTextView wrapper) avec coloration syntaxique Markdown via regex sur `NSTextStorage` (titres, gras, italique, code inline, code blocks, liens, citations, marqueurs de listes)
- [x] Sauvegarde via `FileDocument` (`Cmd+S` natif + auto-save sur perte de focus, géré par DocumentGroup)
- [x] Indicateur "modifié" dans la barre de titre (point dans le close button — comportement NSDocument standard)
- [x] Undo / Redo natif via `NSTextView.allowsUndo = true`
- [x] CFBundleTypeRole : Viewer → Editor

## v3 — Multi-plateforme (Phase A/B/C livrées 2026-05-02, commit `039860a`)

- [x] **Phase A** — Refacto cross-platform de toutes les sources (`#if os(macOS|iOS)`) : WebView dual NS/UIViewRepresentable + Coordinator partagé, MarkdownEditor wrappers NSTextView/UITextView + Highlighter + Palette, ContentView filtre Split sur iPhone + HSplitView→HStack, FindBar débarrassé d'AppKit
- [x] **Phase B** — Second target `MarkdownViewerIOS` dans `project.yml` + `Info-iOS.plist` (UISupportsDocumentBrowser, LSSupportsOpeningDocumentsInPlace, UIFileSharingEnabled, iOS 16+, iPhone+iPad)
- [x] **Phase C** — Asset catalog étendu : entrée universelle 1024x1024 iOS marketing, `Scripts/make-icon.swift` génère le PNG iOS
- [x] **Phase D** — `xcodebuild` iOS Simulator vert (2026-05-02, après install runtime iOS 26.4.1 ~8.5 Go via `xcodebuild -downloadPlatform iOS`). Un fix iOS 16 dans `FindBar.swift` (`.separator` shape style était iOS 17+, remplacé par helper `#if`-guarded `Color(uiColor:.separator)` / `Color(nsColor:.separatorColor)`). Build CLI nécessite `CODE_SIGNING_ALLOWED=NO` à cause du xattr `com.apple.provenance` macOS Sequoia (Xcode IDE gère ça correctement).
- [ ] **Phase E** — Smoke test runtime iPad/iPhone Simulator depuis Xcode IDE (ouvrir un .md, tester preview/split/source, find, print, dark mode auto, frontmatter toggle)
- [ ] **Phase F** — App Store distribution (signing, sandbox audit, review process) — différé
- [ ] Tester compatibilité Files.app + iCloud Drive — à faire en Phase E
- [ ] Live reload iPadOS via `NSFilePresenter` — backlog post-v3 si demande

## v0.2.x — Polish

- [x] Détection + toggle du YAML frontmatter (Obsidian / Tolaria / Jekyll) — bouton 🏷️ dans la toolbar, raccourci `⇧⌘Y`, persisté via `@SceneStorage`, désactivé si pas de frontmatter

## v4 — Auto-update (macOS, depuis GitHub Releases)

- [x] **Choix mécanisme** : version maison (URLSession + GitHub Releases API), Sparkle reporté à plus tard si le projet grandit
- [ ] `Sources/UpdateChecker.swift` (macOS-only via `#if os(macOS)`) : fetch `https://api.github.com/repos/vincentlauriat/MarkdownViewer/releases/latest`, compare `tag_name` vs `CFBundleShortVersionString`, prompt NSAlert "Download" / "Later" si maj dispo
- [ ] Comparaison semver **numérique** (split sur `.` puis compare entiers) — pas la compare lexicographique de String, sinon "1.10" < "1.9"
- [ ] Auto-check au lancement avec debounce 7 jours via `UserDefaults` (`lastUpdateCheck`)
- [ ] Menu "Check for Updates…" après `.appInfo` (CommandGroup) — déclenche le même check en mode "non-silent" (montre "you're up to date" si rien)
- [ ] Bump `MARKETING_VERSION` macOS de `0.1.0` → `0.3.0` dans `project.yml` (alignement avec iOS, sinon premier check trigger une fausse maj)
- [x] Pipeline release : **`Scripts/release.sh <version>`** (build Release + ad-hoc codesign via staging dir avec `ditto --noextattr` pour contourner le `com.apple.provenance` xattr de macOS Sequoia + DMG via `hdiutil`). Imprime la commande `gh release create` à exécuter ensuite.
- [x] **Premier release `v0.3.0` publié** sur GitHub : https://github.com/vincentlauriat/MarkdownViewer/releases/tag/v0.3.0 (DMG 2,49 Mo, ad-hoc signé). API `releases/latest` renvoie bien la release.
- [ ] **Migration future vers Sparkle** : remplacer UpdateChecker, ajouter Sparkle SwiftPM, générer paire EdDSA, configurer `SUFeedURL` + `SUPublicEDKey` dans Info.plist, pipeline release avec `generate_appcast` + notarization Apple Developer ID — **différé**
- [ ] **iOS / iPadOS** : pas applicable hors App Store / TestFlight — feature macOS uniquement

## Backlog (post-v3)

- [ ] Quick Look extension (preview Markdown dans Finder avec barre d'espace)
- [ ] Sélecteur de thèmes CSS (GitHub light/dark, sépia, classique, custom)
- [ ] Table of contents flottante / sidebar
- [ ] Zoom contenu (Cmd +/-)
- [ ] Drag & drop de `.md` sur l'icône Dock (gratuit avec DocumentGroup, à vérifier)
- [ ] Distribution App Store (signing + sandbox + review process)
- [ ] Migrer highlight.js → Shiki si la qualité de coloration devient un problème
- [x] Init repo git + premier commit + repo public GitHub : https://github.com/vincentlauriat/MarkdownViewer
- [x] README anglais top qualité (badges, archi diagram, tech stack, roadmap, contributing)
- [x] LICENSE MIT
