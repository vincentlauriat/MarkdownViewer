import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#elseif os(iOS)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#endif

/// Mapping unifié des couleurs sémantiques (NSColor vs UIColor diffèrent sur les noms).
private enum Palette {
    static var label: PlatformColor {
        #if os(macOS)
        return .labelColor
        #else
        return .label
        #endif
    }
    static var secondaryLabel: PlatformColor {
        #if os(macOS)
        return .secondaryLabelColor
        #else
        return .secondaryLabel
        #endif
    }
    static var quaternaryLabel: PlatformColor {
        #if os(macOS)
        return .quaternaryLabelColor
        #else
        return .quaternaryLabel
        #endif
    }
    static var link: PlatformColor {
        #if os(macOS)
        return .linkColor
        #else
        return .link
        #endif
    }
    static var accent: PlatformColor {
        #if os(macOS)
        return .controlAccentColor
        #else
        return .tintColor
        #endif
    }
}

/// Wrapper d'un text view natif (NSTextView / UITextView) avec coloration syntaxique
/// Markdown basique. SwiftUI's `TextEditor` ne permet pas le styled text — on passe
/// par AppKit / UIKit selon la plateforme.
#if os(macOS)
struct MarkdownEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

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
        textView.postsFrameChangedNotifications = true
        textView.string = text
        context.coordinator.textView = textView
        Highlighter.apply(to: textView.textStorage, baseFont: MarkdownEditor.baseFont)

        let ruler = LineNumberRulerView(textView: textView, scrollView: scroll)
        scroll.verticalRulerView = ruler
        scroll.hasVerticalRuler = true
        scroll.rulersVisible = true
        context.coordinator.ruler = ruler

        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            Highlighter.apply(to: textView.textStorage, baseFont: MarkdownEditor.baseFont)
            context.coordinator.ruler?.needsDisplay = true
        }
    }

    static let baseFont = PlatformFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        weak var textView: NSTextView?
        weak var ruler: LineNumberRulerView?

        init(text: Binding<String>) { self._text = text }

        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            text = view.string
            Highlighter.apply(to: view.textStorage, baseFont: MarkdownEditor.baseFont)
        }
    }
}
#elseif os(iOS)
struct MarkdownEditor: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = MarkdownEditor.baseFont
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no
        textView.spellCheckingType = .no
        textView.dataDetectorTypes = []
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.backgroundColor = .clear
        textView.text = text
        if let storage = textView.layoutManager.textStorage {
            Highlighter.apply(to: storage, baseFont: MarkdownEditor.baseFont)
        }
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            let range = textView.selectedRange
            textView.text = text
            textView.selectedRange = range
            if let storage = textView.layoutManager.textStorage {
                Highlighter.apply(to: storage, baseFont: MarkdownEditor.baseFont)
            }
        }
    }

    static let baseFont = PlatformFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) { self._text = text }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
            if let storage = textView.layoutManager.textStorage {
                Highlighter.apply(to: storage, baseFont: MarkdownEditor.baseFont)
            }
        }
    }
}
#endif

/// Coloration syntaxique très basique du Markdown via regex sur le NSTextStorage.
/// Recoloriage complet à chaque édition — acceptable pour des docs courants
/// (<10k caractères). À optimiser plus tard avec un range incrémental si besoin.
private enum Highlighter {
    static func apply(to storage: NSTextStorage?, baseFont: PlatformFont) {
        guard let storage else { return }
        let str = storage.string as NSString
        let full = NSRange(location: 0, length: str.length)

        storage.beginEditing()
        defer { storage.endEditing() }

        // Reset
        storage.setAttributes([
            .font: baseFont,
            .foregroundColor: Palette.label
        ], range: full)

        let str_ = str as String
        let bg = Palette.quaternaryLabel
        let codeFg = PlatformColor.systemPink
        let accent = Palette.accent
        let secondary = Palette.secondaryLabel

        // Blocs de code ```...```
        regex("```[\\s\\S]*?```").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttributes([
                .foregroundColor: codeFg,
                .backgroundColor: bg
            ], range: r)
        }

        // Titres # à ######
        regex("^(#{1,6})\\s+.+$", [.anchorsMatchLines]).enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            let hashCount = countLeadingHashes(in: str.substring(with: r))
            let size: CGFloat = max(13, 22 - CGFloat(hashCount) * 1.2)
            storage.addAttributes([
                .font: PlatformFont.boldSystemFont(ofSize: size),
                .foregroundColor: accent
            ], range: r)
        }

        // Gras **texte**
        regex("\\*\\*[^*\\n]+\\*\\*").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttribute(.font, value: PlatformFont.boldSystemFont(ofSize: baseFont.pointSize), range: r)
        }

        // Italique *texte*
        regex("(?<!\\*)\\*[^*\\n]+\\*(?!\\*)").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            #if os(macOS)
            let italic = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
            #elseif os(iOS)
            let italic = PlatformFont.italicSystemFont(ofSize: baseFont.pointSize)
            #endif
            storage.addAttribute(.font, value: italic, range: r)
        }

        // Code inline `code`
        regex("`[^`\\n]+`").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttributes([
                .foregroundColor: codeFg,
                .backgroundColor: bg
            ], range: r)
        }

        // Liens [texte](url)
        regex("\\[[^\\]]+\\]\\([^)\\n]+\\)").enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttribute(.foregroundColor, value: Palette.link, range: r)
        }

        // Citations > ...
        regex("^>\\s.*$", [.anchorsMatchLines]).enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttribute(.foregroundColor, value: secondary, range: r)
        }

        // Marqueurs de listes
        regex("^\\s*([-*+]|\\d+\\.)\\s", [.anchorsMatchLines]).enumerateMatches(in: str_, range: full) { m, _, _ in
            guard let r = m?.range else { return }
            storage.addAttribute(.foregroundColor, value: accent, range: r)
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
