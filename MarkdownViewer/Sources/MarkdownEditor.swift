import AppKit
import SwiftUI

/// NSTextView wrapper avec coloration syntaxique Markdown basique.
/// SwiftUI's `TextEditor` ne permet pas le styled text — on passe par AppKit.
struct MarkdownEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.borderType = .noBorder
        scroll.drawsBackground = false

        guard let textView = scroll.documentView as? NSTextView else { return scroll }
        textView.delegate = context.coordinator
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.smartInsertDeleteEnabled = false
        textView.font = MarkdownEditor.baseFont
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.drawsBackground = false
        textView.string = text
        context.coordinator.textView = textView
        Highlighter.apply(to: textView)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        if textView.string != text {
            // Update from outside (live reload, undo on parent, etc.)
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            Highlighter.apply(to: textView)
        }
    }

    static let baseFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?

        init(text: Binding<String>) { self._text = text }

        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            text = view.string
            Highlighter.apply(to: view)
        }
    }
}

/// Coloration syntaxique très basique du Markdown via regex sur le NSTextStorage.
/// Recoloriage complet à chaque édition — acceptable pour des docs courants
/// (<10k caractères). À optimiser plus tard avec un range incrémental si besoin.
private enum Highlighter {
    static func apply(to textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let str = textView.string as NSString
        let full = NSRange(location: 0, length: str.length)

        storage.beginEditing()
        defer { storage.endEditing() }

        // Reset
        storage.setAttributes([
            .font: MarkdownEditor.baseFont,
            .foregroundColor: NSColor.labelColor
        ], range: full)

        let str_ = str as String

        // Blocs de code ```...``` (priorité haute)
        regex("```[\\s\\S]*?```").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttributes([
                .foregroundColor: NSColor.systemPink,
                .backgroundColor: NSColor.quaternaryLabelColor
            ], range: r)
        }

        // Titres # à ######
        regex("^(#{1,6})\\s+.+$", [.anchorsMatchLines]).enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            let hashCount = countLeadingHashes(in: str.substring(with: r))
            let size: CGFloat = max(13, 22 - CGFloat(hashCount) * 1.2)
            storage.addAttributes([
                .font: NSFont.boldSystemFont(ofSize: size),
                .foregroundColor: NSColor.controlAccentColor
            ], range: r)
        }

        // Gras **texte**
        regex("\\*\\*[^*\\n]+\\*\\*").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 13), range: r)
        }

        // Italique *texte* (ne mange pas les **)
        regex("(?<!\\*)\\*[^*\\n]+\\*(?!\\*)").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            let italic = NSFontManager.shared.convert(MarkdownEditor.baseFont, toHaveTrait: .italicFontMask)
            storage.addAttribute(.font, value: italic, range: r)
        }

        // Code inline `code`
        regex("`[^`\\n]+`").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttributes([
                .foregroundColor: NSColor.systemPink,
                .backgroundColor: NSColor.quaternaryLabelColor
            ], range: r)
        }

        // Liens [texte](url)
        regex("\\[[^\\]]+\\]\\([^)\\n]+\\)").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttribute(.foregroundColor, value: NSColor.linkColor, range: r)
        }

        // Citations > ...
        regex("^>\\s.*$", [.anchorsMatchLines]).enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: r)
        }

        // Listes - / * / 1. (juste le marqueur)
        regex("^\\s*([-*+]|\\d+\\.)\\s", [.anchorsMatchLines]).enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttribute(.foregroundColor, value: NSColor.controlAccentColor, range: r)
        }
    }

    private static func regex(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern, options: options)
    }

    private static func countLeadingHashes(in s: String) -> Int {
        var n = 0
        for c in s { if c == "#" { n += 1 } else { break } }
        return n
    }
}
