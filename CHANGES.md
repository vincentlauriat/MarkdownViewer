# Changelog — MarkdownViewer

Format : entrée par session avec date, regroupée par type (`Added` / `Changed` / `Fixed` / `Removed` / `Docs` / `Decisions`).

## 2026-05-01

### Added
- **Scaffolding complet** du projet Xcode généré via XcodeGen :
  - `project.yml` — spec déclarative XcodeGen (cible macOS 13+, Swift 5.9, file association `.md`)
  - `MarkdownViewer/Sources/MarkdownViewerApp.swift` — entry point, `DocumentGroup`, commande Reload (Cmd+R)
  - `MarkdownViewer/Sources/MarkdownDocument.swift` — `FileDocument` avec UTI `net.daringfireball.markdown`
  - `MarkdownViewer/Sources/ContentView.swift` — vue document
  - `MarkdownViewer/Sources/WebView.swift` — `NSViewRepresentable` autour de `WKWebView` avec :
    - chargement local de `web/index.html` via `loadFileURL`
    - injection JS `evaluateJavaScript("window.renderMarkdown(...)")` (encodage via `JSONSerialization` fragments)
    - synchro thème dark/light via observation `effectiveAppearance`
    - clics externes routés vers `NSWorkspace.shared.open`
    - écoute de `NotificationCenter` pour Cmd+R
  - `MarkdownViewer/Resources/web/index.html` — page hôte du rendu
  - `MarkdownViewer/Resources/web/render.js` — pipeline markdown-it + highlight.js + KaTeX + Mermaid + DOMPurify
  - `MarkdownViewer/Resources/Assets.xcassets/` — catalog (AppIcon + AccentColor placeholders)
  - `Scripts/fetch-vendor.sh` — télécharge les libs JS/CSS depuis jsDelivr (versions épinglées)
  - `Scripts/build.sh` — pipeline `xcodegen → fetch-vendor → xcodebuild`
  - `sample.md` — fichier de test couvrant tables, code, math, mermaid, task lists
  - `README.md` — quick start

### Changed
- `ARCHITECTURE.md` n'a pas été modifié, mais l'implémentation s'écarte légèrement :
  - **Shiki remplacé par highlight.js** pour v1 (plus simple à bundler en UMD pour `file://`, ~100 KB vs Shiki ~1-2 MB)
  - **DOMPurify ajouté** comme défense en profondeur autour de l'injection HTML (bonne pratique malgré `html: false` dans markdown-it)
  - **Live reload reporté** : `FileDocument` (struct) n'expose pas l'URL du fichier en API publique SwiftUI ; reload manuel via Cmd+R en attendant un passage à `ReferenceFileDocument` ou un observer `NSDocumentController`

### Decisions
- **XcodeGen** comme source de vérité du projet Xcode (le `.xcodeproj` est `.gitignore`)
- **Sandbox désactivée** en MVP (simplifie file access pour live reload futur ; à réactiver si distribution App Store)
- **Pas de signing** en dev (`CODE_SIGN_IDENTITY: -`), à arbitrer pour distribution

### Verified
- `xcodebuild` Debug : ✅ BUILD SUCCEEDED
- App générée à `build/Build/Products/Debug/MarkdownViewer.app`
- LaunchServices a enregistré l'app automatiquement (file association `.md` active)
- Resources bundlées correctement (`Contents/Resources/web/` avec tous les vendors)
- **Test runtime** : `open -a MarkdownViewer.app sample.md` → app lancée, fenêtre visible, WebKit a chargé index.html, idle à 0.2% CPU. Logs propres (aucun crash, aucune erreur Swift/WebKit). Vérification visuelle finale par Vincent.

### Notes
- `screencapture` et `osascript` System Events bloqués par TCC (permissions Screen Recording / Accessibility non accordées au shell). Le test runtime s'appuie donc sur les logs `log show` qui sont toujours accessibles.

---

## Phase 4 — Live reload (terminée)

### Added
- `MarkdownViewer/Sources/FileWatcher.swift` :
  - `DispatchSource.makeFileSystemObjectSource` sur file descriptor `O_EVTONLY`
  - eventMask `[.write, .delete, .rename, .extend]`
  - debounce 120 ms via `Task.sleep` (évite double trigger sur atomic save)
  - re-binding automatique sur nouveau fd après `.delete` / `.rename` (gère vim/VS Code/Sublime)
  - cleanup propre dans `deinit` et `stop()`
- `WebView.Coordinator.attachFileWatcherIfPossible()` : récupère `webView.window?.representedURL` (posée par `DocumentGroup`) avec retry 10×100 ms (la window pop après `didFinishNavigation`)
- Champ `liveMarkdown` dans le Coordinator : prime sur `documentMarkdown` quand le watcher a relu une version plus récente que celle envoyée par SwiftUI

### Changed
- Tous les `NSLog` remplacés par `os.Logger` avec subsystem `com.vincent.MarkdownViewer` et catégories `WebView` / `FileWatcher` — désormais visibles dans `log show --predicate 'subsystem == "com.vincent.MarkdownViewer"' --info`

### Verified (test runtime)
- Test 1 — write inline (`echo >> sample.md`) :
  - 2 events `.write/.extend` reçus → debounce → 1 reload → 133 ms entre modif et re-rendu ✅
- Test 2 — atomic save (`mv tmp sample.md`) :
  - 1 event `.delete` (raw=1, needsRebind=true) → ré-attachement du watcher sur nouveau fd → reload → 126 ms ✅
- Pas besoin de migrer vers `ReferenceFileDocument` : `representedURL` est posée par DocumentGroup automatiquement

---

## Phase 5 — Find / Print + GitHub release (terminée)

### Added
- `MarkdownViewer/Sources/FindBar.swift` : SwiftUI floating find bar
  - NSSearchField-like (champ + boutons up/down + close)
  - Style `.thinMaterial` avec radius 10, ombre légère, transition slide-in/out
  - `@FocusState` auto-focus à l'ouverture, Esc pour fermer
  - Recherche live au typing + Enter pour next
- `MarkdownViewer/Sources/ContentView.swift` : `ZStack` overlay avec `FindBar` aligné top-trailing
- `MarkdownViewer/Sources/MarkdownViewerApp.swift` : 5 nouvelles commandes menu :
  - `Cmd+P` Print (replacing `.printItem`)
  - `Cmd+F` Find (replacing `.textEditing`)
  - `Cmd+G` / `Cmd+Shift+G` Find Next/Previous
  - `Cmd+R` Reload (déjà existant)
- `WebView.Coordinator` : 5 nouveaux observers via helper `observe(_:action:)` :
  - `.printActiveDocument` → `webView.printOperation(with: NSPrintInfo.shared).runModal(...)`
  - `.findRequest(query, forward)` → `webView.find(_:configuration:)` natif macOS 12+
  - `.findNext` / `.findPrevious` → reuse de `lastFindQuery`
  - Filtrage `isActiveWebView()` (via `window.isKeyWindow`) pour ne pas déclencher dans les fenêtres inactives

### Changed
- Helper `observe(_:action:)` typé `@MainActor @Sendable (Notification) -> Void` pour passer la stricte concurrence Swift 6
- `Coordinator` : remplacement de l'unique `reloadObserver` par un tableau `observers: [NSObjectProtocol]` (cleanup unifié dans `deinit`)

### Added (project files)
- `LICENSE` : MIT
- `README.md` : refonte complète en anglais — badges, hero, features table, quick start, set as default, architecture diagram ASCII, tech stack table, project layout, dev commands, roadmap, contributing, license

### Decisions
- API native `WKWebView.find(_:configuration:)` (macOS 12+) plutôt que `window.find()` JS ou `NSTextFinder` — plus simple, gère wrap automatiquement
- Pas de compteur "X of Y matches" en MVP (l'API native ne le retourne pas, demanderait du JS injection en plus)
- `keyboardShortcut(.escape)` sur le bouton close de `FindBar` plutôt qu'une logique custom
- Floating bar SwiftUI plutôt qu'NSPanel séparée — reste dans la window du document, suit son focus

### Verified
- Build OK après 2 fix Swift 6 concurrency (`@MainActor` sur le helper `observe`, downgrade `onChange(of:initial:_:)` macOS 14+ → `onChange(of:)` macOS 13)
- Runtime : file watcher s'arme correctement sur sample.md, logs `os.Logger` capturés
- Find / Print non-testables sans GUI access — validation visuelle déléguée à Vincent

### Released
- Repo public : https://github.com/vincentlauriat/MarkdownViewer
- Premier commit "feat: initial release of MarkdownViewer v0.1.0"
- Branch `main` avec upstream tracking

### Docs
- Création de la documentation initiale du projet :
  - `MEMORY.md` — synthèse vivante du projet
  - `TODOS.md` — backlog par version (v1 MVP, v2 édition, v3 multi-plateforme)
  - `ARCHITECTURE.md` — choix techniques détaillés
  - `PLAN.md` — plan d'implémentation en 7 phases
  - `CHANGES.md` — ce fichier
  - `COMMANDS.md` — historique des consignes utilisateur
  - `CLAUDE.md` — règles projet auto-chargées par Claude
  - `.gitignore` — exclut build/, DerivedData/, .xcodeproj/, vendor/

### Fixed
- Première itération de `project.yml` plaçait les ressources dans une clé `resources:` inexistante (XcodeGen attend `sources:` avec `buildPhase: resources`). Corrigé : web/ et Assets.xcassets sont maintenant correctement copiées dans le bundle.
