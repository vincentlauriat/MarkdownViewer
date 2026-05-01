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
- [ ] App icon (placeholder OK pour début)
- [ ] Test sur fichiers de stress : README de gros repos, fichier de 1 Mo, doc avec 100 images
- [ ] Vérifier signing minimal (Developer ID ou self-signed pour usage perso)
- [x] Test runtime : ouvrir sample.md, vérifier rendu (math, code highlight, mermaid, dark mode) — validé visuellement « c'est super propre »
- [x] NSLog → `os.Logger` avec subsystem `com.vincent.MarkdownViewer` (observabilité fiable via `log show`)
- [x] Build Release + install dans `/Applications/MarkdownViewer.app` (4,4 Mo)
- [x] Définir l'app comme handler par défaut `.md` dans Finder via `duti` (couvre aussi `markdown`, `mdown`, `mdwn`, `mkd`, `mkdn`, `public.plain-text`)

## v2 — Édition

- [ ] Toggle Preview / Code (segmented control toolbar)
- [ ] Mode split (preview + code côte à côte) — optionnel
- [ ] Éditeur de texte natif (`TextEditor` SwiftUI) avec coloration syntaxique Markdown basique
- [ ] Sauvegarde via `FileDocument` (auto-save quand fenêtre perd le focus)
- [ ] Indicateur "modifié" dans la barre de titre (point dans le bouton fermer)
- [ ] Undo / Redo natif

## v3 — Multi-plateforme

- [ ] Cible iPadOS — réutiliser `DocumentGroup` (déjà cross-platform)
- [ ] Cible iOS — adapter UI compacte (toggle plutôt que split)
- [ ] Tester compatibilité Files.app + iCloud Drive

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
