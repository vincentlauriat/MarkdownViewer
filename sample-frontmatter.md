---
title: Note avec frontmatter
date: 2026-05-02
tags: [markdown, obsidian, tolaria]
aliases:
  - "MD viewer test"
  - "Frontmatter sample"
status: draft
author: Vincent
---

# Note avec frontmatter YAML

Ce document commence par un bloc `---` … `---` qu'on appelle **frontmatter**. Obsidian, Tolaria, Jekyll, Hugo et beaucoup d'autres outils utilisent ce format pour stocker des métadonnées.

## Comportement attendu dans MarkdownViewer

- Par défaut, le bloc est **masqué** (lecture nettoyée)
- Cliquer sur le bouton 🏷️ dans la toolbar (ou `⇧⌘Y`) **affiche** le bloc dans une box stylée
- Le bouton est désactivé si le document n'a pas de frontmatter

## Reste du contenu

Lorem ipsum dolor sit amet. Voici du **gras**, de l'*italique*, du `code inline`.

```python
def hello(name):
    return f"Hello, {name}!"
```

Et un peu de math : $E = mc^2$
