---
name: MarkdownViewer — Mémoire projet
description: Synthèse vivante du projet, mise à jour automatiquement à chaque évolution
last_updated: 2026-05-01T13:10
---

# MarkdownViewer — Mémoire projet

## Pitch
Application macOS native pour visualiser rapidement un fichier `.md` au double-clic depuis le Finder, avec édition différée en v2 et déclinaisons iPadOS / iOS prévues plus tard.

## Décisions structurantes (figées)
- **Pile** : SwiftUI natif (Xcode), architecture document-based via `DocumentGroup`.
- **Rendu Markdown** : `WKWebView` + assets web locaux bundlés (markdown-it + highlight.js + KaTeX + Mermaid + DOMPurify + thème GitHub).
- **Cible initiale** : macOS 13+ (Ventura). iOS/iPadOS plus tard avec partage maximal du code.
- **Project file** : généré via XcodeGen depuis `project.yml` (le `.xcodeproj` n'est pas commité).
- **Distribution** : non arbitré — pas de signing en dev (`-`), sandbox désactivée. App Store ou Developer ID à choisir avant release.
- **Note** : Shiki remplacé par highlight.js en MVP (plus simple à bundler), réversible si besoin de meilleurs thèmes.

## Périmètre MVP (v1) — validé
**Indispensables — tous implémentés**
- File association `.md` / `.markdown` (double-clic Finder ouvre l'app)
- Multi-fenêtres (un document = une fenêtre, comportement macOS standard)
- Dark mode auto (suit le système)
- Sélection / copier le texte rendu
- Pipeline complet de rendu Markdown (tables, code, math, mermaid, task lists)

**Inclus en plus — implémentés**
- Recent files (gratuit avec `DocumentGroup`, à vérifier au runtime)
- Reload manuel Cmd+R
- **Live reload automatique** (debounce 120 ms, gestion atomic save vim/VS Code, latence ~130 ms)
- Observabilité via `os.Logger` (subsystem `com.vincent.MarkdownViewer`)

**Reportés**
- Find in document (Cmd+F)
- Print / Export PDF (Cmd+P)

## Hors MVP (v2 et au-delà)
- v2 : édition + toggle preview / code (split ou bascule)
- v3 : iPadOS / iOS
- Plus tard : sélecteur de thèmes, table of contents flottante, zoom Cmd+/-, Quick Look extension

## État courant
- **Phase** : Phases 0-5 du PLAN.md terminées — MVP fonctionnel
- **Repo** : https://github.com/vincentlauriat/MarkdownViewer (public, MIT, README anglais)
- **Build** : ✅ `xcodebuild` Debug réussit, app à `build/Build/Products/Debug/MarkdownViewer.app`
- **LaunchServices** : app enregistrée automatiquement (file association `.md` active)
- **Live reload** : opérationnel, latence ~130 ms (write + atomic save)
- **Find / Print** : implémentés (`Cmd+F`, `Cmd+G`, `Cmd+Shift+G`, `Cmd+P`, `Cmd+R`), validation visuelle Vincent en attente
- **Prochaines étapes** : polish v1 (app icon, définir handler par défaut, signing Developer ID éventuel) puis attaque v2 (édition)

## Quick start
```bash
cd ~/Documents/GitHub/MarkdownViewer
./Scripts/build.sh run      # build + lance l'app
open -a build/Build/Products/Debug/MarkdownViewer.app sample.md
```

## Liens rapides
- [TODOS.md](./TODOS.md) — découpage par features
- [ARCHITECTURE.md](./ARCHITECTURE.md) — choix techniques détaillés
- [PLAN.md](./PLAN.md) — plan d'implémentation par phases
- [CHANGES.md](./CHANGES.md) — journal des modifications
- [COMMANDS.md](./COMMANDS.md) — historique des consignes utilisateur
- [CLAUDE.md](./CLAUDE.md) — règles auto-chargées par Claude
- [README.md](./README.md) — quick start
