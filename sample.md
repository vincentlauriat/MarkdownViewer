# MarkdownViewer — Sample

Bienvenue ! Ce fichier teste tout le pipeline de rendu.

## Styles de texte

Texte normal, **gras**, *italique*, ***les deux***, ~~barré~~, `code inline`, [un lien](https://github.com).

## Listes

- premier
- deuxième
  - imbriqué
- troisième

1. ordonné
2. ordonné
3. ordonné

## Tâches

- [x] Initialiser le projet
- [x] Bundler les assets web
- [x] Implémenter le live reload
- [x] Find / Print / Export PDF
- [ ] Ajouter le mode édition (v2)

## Code

```swift
import SwiftUI

@main
struct MarkdownViewerApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            ContentView(document: file.document)
        }
    }
}
```

```python
def fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
```

## Tableau

| Feature | Status | Notes |
|---|:---:|---|
| Tables GFM | ✅ | natif markdown-it |
| Coloration code | ✅ | highlight.js |
| Math LaTeX | ✅ | KaTeX |
| Mermaid | ✅ | v10 |
| Task lists | ✅ | plugin GFM |
| Live reload | ✅ | DispatchSource, ~130 ms |
| Find / Print | ✅ | natif WKWebView |

## Math

Inline : $E = mc^2$ — équation classique.

Display :
$$\int_{0}^{\infty} e^{-x^{2}}\, dx = \frac{\sqrt{\pi}}{2}$$

## Mermaid

```mermaid
graph LR
  A[Finder] -->|double-clic| B[MarkdownViewer]
  B --> C[WKWebView]
  C --> D[markdown-it]
  D --> E[Render]
```

## Citation

> "Simplicity is the ultimate sophistication."
> — Leonardo da Vinci

---

Made with ❤️ + SwiftUI + WKWebView
