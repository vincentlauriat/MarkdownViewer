# Plan d'implémentation — MarkdownViewer

## Phase 0 — Scaffolding (~1 h)

**Objectif** : projet Xcode qui se lance et affiche une fenêtre vide.

1. Créer le projet : Xcode → File → New → Project → macOS → App
   - Product Name : `MarkdownViewer`
   - Interface : SwiftUI
   - Language : Swift
   - Storage : None (on basculera vers DocumentGroup)
2. Convertir `App.swift` en architecture document-based : `DocumentGroup(newDocument: ...)`
3. Créer `MarkdownDocument: FileDocument` avec `readableContentTypes = [.text]` provisoire
4. Build & run → vérifier qu'une fenêtre s'ouvre sur Cmd+N
5. Commit initial

**Critère de succès** : `xcodebuild` compile, l'app se lance et crée des fenêtres vides.

## Phase 1 — File association `.md` (~30 min)

**Objectif** : double-clic sur un `.md` dans Finder ouvre l'app.

1. Déclarer le UTI dans `Info.plist` :
   - `UTImportedTypeDeclarations` : conformant à `public.plain-text`, identifier `net.daringfireball.markdown`, extensions `md`, `markdown`, `mdown`, `mdwn`
   - `CFBundleDocumentTypes` : role `Viewer` (puis `Editor` en v2), UTI référencé ci-dessus
2. Mettre à jour `MarkdownDocument.readableContentTypes` avec un `UTType` custom
3. Build & run, puis dans Finder : clic droit sur un `.md` → Get Info → Open with → MarkdownViewer → Change All
4. Tester double-clic

**Critère de succès** : double-clic sur `.md` ouvre l'app avec une fenêtre dédiée au fichier.

## Phase 2 — WKWebView intégré (~2 h)

**Objectif** : afficher le contenu brut du Markdown dans un `WKWebView`.

1. Créer `WebViewBridge: NSViewRepresentable` qui retourne un `WKWebView`
2. Créer `PreviewView` qui prend un `MarkdownDocument` en `@Binding`
3. Charger un `index.html` minimal bundlé (`<body><pre id="raw"></pre></body>`)
4. Injecter le contenu via `evaluateJavaScript("document.getElementById('raw').textContent = ...")`
5. Vérifier dark mode système basique

**Critère de succès** : ouvrir un `.md` affiche son contenu brut dans la fenêtre.

## Phase 3 — Rendu Markdown complet (~3 h)

**Objectif** : rendu HTML stylé GitHub-like avec tables, code coloré, math, mermaid.

1. Bundler les assets web dans `Resources/web/` :
   - `markdown-it.min.js` (+ plugins `markdown-it-task-lists`, `markdown-it-katex`)
   - `shiki.min.js` + thèmes `github-light` / `github-dark` + 10 langages courants
   - `katex.min.js` + `katex.min.css`
   - `mermaid.min.js`
   - `github-markdown.css` (theme officiel)
2. Écrire `render.js` qui expose `window.renderMarkdown(text)` → parse → applique Shiki sur les `<pre><code>` → KaTeX sur `$...$` → Mermaid sur les blocs `mermaid`
3. Synchro thème : Swift observe `effectiveAppearance` et appelle `setTheme('dark'|'light')`
4. Tester sur 5 fichiers variés (README de gros repo, doc avec math, doc avec mermaid, doc avec gros tableaux)

**Critère de succès** : rendu visuellement comparable à GitHub, dark mode propre.

## Phase 4 — Live reload (~1 h)

**Objectif** : modifier le `.md` dans VS Code rafraîchit la fenêtre automatiquement.

1. Créer `FileWatcher` avec `DispatchSource.makeFileSystemObjectSource(fileDescriptor:eventMask:.write,.rename, queue:)`
2. Debouncer à 100 ms
3. Sur événement, relire le fichier et appeler `renderMarkdown(...)` à nouveau
4. Gérer le cas atomic save (rename) : ré-ouvrir un nouveau file descriptor sur le path

**Critère de succès** : éditer le `.md` dans un autre éditeur met à jour la preview en <500 ms.

## Phase 5 — Find / Print / Recent (~1 h)

**Objectif** : finitions natives.

1. Find : exposer `Cmd+F` qui appelle `webView.find(_:configuration:)` (API macOS 12+)
2. Print : commande menu → `webView.printOperation(with: NSPrintInfo.shared).run()`
3. Recent : vérifier qu'`Open Recent` dans le menu File fonctionne (gratuit avec DocumentGroup)
4. Tester export PDF via "Save as PDF" dans la dialog d'impression

**Critère de succès** : les 4 fonctionnalités marchent, l'app se sent native.

## Phase 6 — Polish + signing (~1 h)

1. App icon (placeholder Sparkle ou icône Markdown générique)
2. Signing local (Developer ID si compte Apple Developer, sinon ad-hoc)
3. Test sur fichiers de stress
4. Tagger v1.0

**Critère de succès** : app utilisable au quotidien, prête à être ton handler par défaut.

## Phases v2 / v3

- **v2 — Édition** : voir TODOS.md → implémentation TBD après validation v1
- **v3 — iPadOS / iOS** : ajouter cible Universal au projet, ajuster UI compacte

## Estimation totale v1
~8-10 h de dev effectif réparties sur 2-3 sessions.
