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
- [x] Export PDF direct (sans passer par le dialog d'impression) — livré 2026-08-04, bouton toolbar + *File → Export as PDF…*, `NSSavePanel` + `NSPrintInfo.jobDisposition = .save` sur le même `printOperation`. Inspiré de la toolbar BmadBrowser.

### Polish v1
- [x] App icon — "M↓" indigo squircle, généré par `Scripts/make-icon.swift` (10 tailles + Contents.json)
- [ ] Test sur fichiers de stress : README de gros repos, fichier de 1 Mo, doc avec 100 images
- [x] Vérifier signing minimal — dépassé : releases signées Developer ID + Hardened Runtime + notarized depuis v0.5.1
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

## v4 — Auto-update (macOS, depuis GitHub Releases) — livré puis remplacé par Sparkle en v0.6

- [x] **Choix mécanisme** : version maison (URLSession + GitHub Releases API), Sparkle reporté à plus tard si le projet grandit
- [x] `Sources/UpdateChecker.swift` (macOS-only) : fetch `releases/latest`, compare semver numérique, NSAlert Download/Later/Skip — **supprimé en v0.6, remplacé par Sparkle**
- [x] Auto-check au lancement avec debounce 7 jours + menu "Check for Updates…" (non-silent)
- [x] Bump `MARKETING_VERSION` macOS `0.1.0` → `0.3.0` dans `project.yml`
- [x] Pipeline release : **`Scripts/release.sh <version>`** (build Release + codesign via staging dir `ditto --noextattr` + DMG via `hdiutil`). Imprime la commande `gh release create` à exécuter ensuite.
- [x] **Premier release `v0.3.0` publié** sur GitHub : https://github.com/vincentlauriat/MarkdownViewer/releases/tag/v0.3.0
- [x] **Migration vers Sparkle** — faite en v0.6.0 (Sparkle 2.9.1 SwiftPM, paire EdDSA, `SUFeedURL` + `SUPublicEDKey`, appcast généré par `release.sh`)
- [-] **iOS / iPadOS** : pas applicable hors App Store / TestFlight — feature macOS uniquement

## v0.5 — Polish éditeur (livré 2026-05-04)

- [x] Numéros de ligne dans une marge gauche (gutter) sur le `MarkdownEditor`, modes Source + Split, **macOS uniquement** — `NSRulerView` sous-classée, ~170 lignes Swift, spec : `docs/superpowers/specs/2026-05-03-line-numbers-gutter-design.md`. Validé visuellement par Vincent le 2026-05-04 sur `sample-long.md` (541 lignes, transition 2→3 digits, soft-wrap, mode Source + Split, dark/light, undo)
- [x] **Notarized release pipeline (v0.5.1)** — Developer ID + Hardened Runtime + notarytool submit + stapler staple dans `Scripts/release.sh`. Plus de "right-click → Open" Gatekeeper sur les versions notarized.

## v0.7 — Zoom + highlight ligne courante (livré 2026-05-05)

- [x] **F — Zoom contenu** (`⌘+` / `⌘-` / `⌘0`) — `WKWebView.pageZoom` piloté par `@SceneStorage("zoomRatio")`, step 0.1, range [0.5, 3.0]. macOS only.
- [x] **D — Highlight ligne courante dans le gutter** — `LineNumberRulerView` observe la sélection du `NSTextView`, dessine le numéro en bold + `controlAccentColor`. Toggle via menu + `@SceneStorage`.
- [x] **G — Drag&drop `.md` sur l'icône Dock** — gratuit avec `DocumentGroup`, validé visuellement par Vincent au runtime (2026-05-05).

## v0.6 — Auto-update Sparkle + Help/What's New/About internes (livré 2026-05-04)

- [x] **Sparkle 2** intégré via SwiftPM — remplace le `UpdateChecker` maison. UI moderne, Install-and-Relaunch one-click, EdDSA signature en plus de la notarization Apple. `appcast.xml` hébergé dans `main` (raw.githubusercontent.com).
- [x] **Fenêtre Help interne** (`⌘?`) — fetch README depuis GitHub raw, rendu via le `WebView` existant, bouton "View README on GitHub".
- [x] **Fenêtre What's New interne** — fetch `/releases` via API GitHub, concat des release notes, rendu via WebView, bouton "View all releases on GitHub".
- [x] **Fenêtre About custom** — `CommandGroup(replacing: .appInfo)` + `AboutWindowView` avec icon, version, description, bouton "View on GitHub", copyright. `windowResizability(.contentSize)`.
- [x] **`Scripts/release.sh`** étendu — auto-fetch Sparkle CLI tools, sign chaque sub-binary de `Sparkle.framework` (Autoupdate + 2 XPC + Updater.app + framework), génère `appcast.xml` automatiquement.
- [x] **`UpdateChecker.swift` supprimé** — Sparkle prend tout en charge.
- [x] **Bug fix** — stack overflow dans `HelpWindows.swift` causé par une extension `View.footer` qui wrappait `self`. Refactorisé en `FooterBar` sibling struct.

## v0.8 — Quick Look + robustesse (livré : v0.8.0 le 2026-05-05, v0.8.1 le 2026-06-14)

- [x] **Quick Look extension** (`MarkdownViewerQL`) — preview Finder barre d'espace, même pipeline web, sandbox read-only, validé en prod sur release Developer ID
- [x] **What's New épuré** — endpoint `/releases/latest`, un seul bloc de notes au lieu de tout l'historique
- [x] **Workaround crash CoreAnimation/Metal (v0.8.1)** — fenêtre épinglée sRGB 8-bit (`window.colorSpace = .sRGB` + `contentsFormat = .RGBA8Uint`) + WebView opaque, contourne les shaders half-float manquants sur M4 (macOS 26.5.1 / 27.0 beta). Validé au scroll par Vincent.
- [x] **Escalade crash : `toneMapMode = .never` (2026-07-05)** — couche WebView + arbre de layers complet de chaque fenêtre au `didBecomeKey`, après récidive sur cache Metal vierge (hypothèse cache corrompu réfutée). Branche `fix/tonemap-never-mitigation`, build + tests OK — **validation scroll confirmée par Vincent (2026-07-18)**.
- [ ] **Soumettre le rapport de bug à Apple** via Feedback Assistant (`docs/apple-feedback-coreanimation-crash.md` + 13 `.ips` dans `docs/crash-reports/`) — **encore plus urgent** : l'hypothèse cache est réfutée, seul Apple peut corriger la racine
- [x] **Rotation clé Sparkle assumée** — clé `9PD2` officielle, warning DO NOT REGENERATE dans `release.sh`, note « update manuel une fois » dans les release notes v0.8.1
- [x] **Backup de la clé privée Sparkle** hors keychain — fait le 2026-07-02, intégrité vérifiée par signature comparée (emplacement documenté dans MEMORY.md ; reste à le copier dans un gestionnaire de mots de passe)

## v0.9.1 — Robustesse crash + Save As (livrée 2026-07-18)

- [x] **CrashRecovery** (`Sources/CrashRecovery.swift`) — watchdog `/bin/sh` détaché qui survit au process, relance l'app après une sortie anormale (le crash CoreAnimation/Metal ci-dessus peut encore `abort()` le process depuis son propre thread de rendu, sans code app sur la pile fautive). Marqueur de session dans Application Support (epoch + compteur de relances + documents ouverts), garde-fou 3 relances consécutives max, reset après 60 s de session saine, purge le Saved Application State d'Apple après une relance (observé : conflit CoreUI recursive-lock au premier rendu sinon).
- [x] **Save As… visible dans le menu File** — `CommandGroup(after: .saveItem)` envoie `NSDocument.saveAs(_:)` via la responder chain. Le natif `.saveItem` par défaut de `DocumentGroup` expose déjà "Save As…" mais uniquement caché derrière ⌥ (alternate de "Duplicate") — item ajouté pour le rendre toujours visible, sans remplacer le groupe par défaut (`CommandGroup(replacing: .saveItem)` casse le bridge SwiftUI/NSDocument : Save lui-même cesse de fonctionner, vérifié empiriquement avant d'adopter la bonne approche).

## Backlog (post-v3)

- [x] Quick Look extension (preview Markdown dans Finder avec barre d'espace) — livré v0.8.0, validé par Vincent en prod
- [x] Sélecteur de thèmes (Auto / GitHub Light / GitHub Dark / Sépia) — livré le 2026-07-02 (branch `feat/theme-picker`) : menu 🎨 toolbar, persisté par fenêtre, thème forcé via appearance de la WKWebView, palette sépia via custom properties CSS. Extension future : thèmes custom utilisateur.
- [x] Table of contents flottante / sidebar — livré 2026-08-04 sous forme de menu toolbar "Plan" (`MarkdownOutline.swift`, pas une sidebar : outline calculé côté Swift, scroll géré côté JS par index) ; branche `feature/outline-toolbar`, inspiré de la toolbar BmadBrowser
- [x] Zoom contenu (Cmd +/-) — livré v0.7.0
- [x] Drag & drop de `.md` sur l'icône Dock (gratuit avec DocumentGroup) — validé v0.7.0
- [ ] Distribution App Store (signing + sandbox + review process)
- [ ] Migrer highlight.js → Shiki si la qualité de coloration devient un problème
- [x] Init repo git + premier commit + repo public GitHub : https://github.com/vincentlauriat/MarkdownViewer
- [x] README anglais top qualité (badges, archi diagram, tech stack, roadmap, contributing)
- [x] LICENSE MIT

## Dette technique & qualité (identifiée le 2026-07-02, socle livré le 2026-07-02 — branch `chore/quality-foundation`)

- [x] Supprimer les projets périmés `MarkdownViewer 2.xcodeproj` / `MarkdownViewer 3.xcodeproj`
- [x] Premiers tests automatisés — cible `MarkdownViewerTests` (hosted), 25 tests / 3 suites : `WebPipelineTests` (encodeForJS + frontmatter), `HighlighterTests` (regex/attributs), `FileWatcherTests` (write in-place, atomic save + rebind, stop)
- [x] Factoriser le code dupliqué app ↔ extension QL — `Sources/Shared/WebPipeline.swift` (`encodeForJS`, `hasFrontmatter`, `darkBackground`), compilé dans les 3 cibles
- [x] Désactiver `developerExtrasEnabled` (KVC privé) hors Debug — `#if os(macOS) && DEBUG`
- [x] Supprimer le code mort `ViewMode.cycled()` (aurait d'ailleurs été incorrect sur iPhone : ne filtrait pas Split)
- [x] Centraliser la couleur dark `#0d1117` côté Swift (`WebPipeline.darkBackground`, commentaire de synchro vers le CSS)
- [ ] Centraliser les URLs GitHub hardcodées (HelpWindows + release.sh)
- [x] Remonter les erreurs `evaluateJavaScript` dans `os.Logger` (flush / setTheme / frontmatter, app + QL) + `console.error` dans les catch highlight/mermaid de render.js
- [x] Retrait du KVC privé `drawsBackground=false` dans le QL (aligné sur le workaround crash : fond opaque via CSS)
- [x] CI GitHub Actions — `.github/workflows/ci.yml` : build + tests macOS, build iOS Simulator (à valider au premier run sur GitHub)
