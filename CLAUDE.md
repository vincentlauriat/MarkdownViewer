# CLAUDE.md — Instructions projet MarkdownViewer

Ces règles sont chargées automatiquement à chaque session Claude dans ce dossier. Elles complètent les règles globales `~/.claude/CLAUDE.md` et `~/Documents/GitHub/CLAUDE.md`.

## Règle d'auto-maintenance des fichiers de doc

À chaque interaction avec Vincent, **sans qu'il ait besoin de le rappeler**, mettre à jour :

| Fichier | Quand le mettre à jour | Contenu |
|---|---|---|
| `COMMANDS.md` | À chaque message reçu de Vincent | Ajouter le message en bas avec date + numéro incrémental |
| `CHANGES.md` | Dès qu'une modification réelle est faite (code, doc, config) | Ajouter une entrée datée groupée par type (Added/Changed/Fixed/Removed/Docs/Decisions) |
| `MEMORY.md` | Quand une décision structurante est prise OU que l'état du projet change (phase terminée, nouveau périmètre…) | Mettre à jour la section concernée + le champ `last_updated` du frontmatter |
| `TODOS.md` | Quand une tâche est terminée OU qu'une nouvelle est identifiée | Cocher / ajouter / déplacer entre sections |
| `PLAN.md` | Si l'ordonnancement ou le découpage des phases change | Mettre à jour les phases concernées |
| `ARCHITECTURE.md` | Si un choix technique change ou est précisé | Mettre à jour le diagramme / les tables / la section concernée |

### Comment appliquer
- Faire ces mises à jour **dans le même tour** que la modification, pas en différé.
- Pour `COMMANDS.md` : si le message est trivial ("ok", "merci"), le logger quand même — c'est un journal exhaustif.
- Si la modification touche plusieurs fichiers de doc, regrouper les `Write`/`Edit` en parallèle dans une seule réponse.
- Ne jamais sauter une mise à jour pour aller plus vite — la cohérence de la doc est non-négociable.

### Pourquoi
Vincent veut que ces fichiers restent toujours synchronisés sans avoir à le demander. Il s'appuie dessus pour reprendre le projet entre sessions. Une doc obsolète vaut moins que pas de doc.

## Convention de langue
- Communication avec Vincent : **français** (avec accents complets)
- Identifiants de code, commits, code Swift : **anglais**
- Fichiers de doc : **français**

## Convention de commits
Pas encore initialisé en repo git. Quand ce sera le cas :
- Suffixe `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` à chaque commit
- Messages courts en anglais, présent ("add", "fix", "update")

## Périmètre actuel
Voir `MEMORY.md` pour l'état à jour du projet et `TODOS.md` pour la liste des tâches.
