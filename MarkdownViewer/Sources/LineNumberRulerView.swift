import SwiftUI

#if os(macOS)
import AppKit

/// Gutter de numéros de ligne pour le `MarkdownEditor`.
/// Sous-classe `NSRulerView` attachée comme `verticalRulerView` du `NSScrollView`,
/// donc synchro automatique avec le scroll, le wrapping et le redimensionnement.
/// Convention Xcode/VS Code : les paragraphes wrappés n'ont qu'un numéro (sur la 1re ligne visuelle).
final class LineNumberRulerView: NSRulerView {
    private weak var observedTextView: NSTextView?
    private var notificationTokens: [NSObjectProtocol] = []

    private static let numberFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    private static let horizontalPadding: CGFloat = 12
    private static let trailingInset: CGFloat = 6
    private static let minimumThickness: CGFloat = 28

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.observedTextView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = Self.minimumThickness
        recomputeThickness()
        registerObservers(textView: textView, scrollView: scrollView)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        for token in notificationTokens {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private func registerObservers(textView: NSTextView, scrollView: NSScrollView) {
        let center = NotificationCenter.default

        notificationTokens.append(center.addObserver(
            forName: NSText.didChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            self?.recomputeThickness()
            self?.needsDisplay = true
        })

        scrollView.contentView.postsBoundsChangedNotifications = true
        notificationTokens.append(center.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak self] _ in
            self?.needsDisplay = true
        })

        notificationTokens.append(center.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: textView,
            queue: .main
        ) { [weak self] _ in
            self?.needsDisplay = true
        })
    }

    private func recomputeThickness() {
        guard let textView = observedTextView else { return }
        let lineCount = max(1, lineCountInString(textView.string))
        let digits = max(2, Int(ceil(log10(Double(lineCount + 1)))))
        let attrs: [NSAttributedString.Key: Any] = [.font: Self.numberFont]
        let digitWidth = ("0" as NSString).size(withAttributes: attrs).width
        let needed = CGFloat(digits) * digitWidth + Self.horizontalPadding + Self.trailingInset
        let newThickness = max(Self.minimumThickness, ceil(needed))
        if abs(newThickness - ruleThickness) > 0.5 {
            ruleThickness = newThickness
            invalidateHashMarks()
        }
    }

    private func lineCountInString(_ s: String) -> Int {
        if s.isEmpty { return 1 }
        var count = 1
        for ch in s.utf8 where ch == 0x0A { count += 1 }
        return count
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = observedTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        NSColor.textBackgroundColor.setFill()
        bounds.fill()

        NSColor.quaternaryLabelColor.setStroke()
        let separator = NSBezierPath()
        separator.move(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY))
        separator.line(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
        separator.lineWidth = 1
        separator.stroke()

        let nsString = textView.string as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Self.numberFont,
            .foregroundColor: NSColor.tertiaryLabelColor
        ]

        if nsString.length == 0 {
            drawNumber(1, atTextContainerY: 0, textView: textView, attrs: attrs)
            return
        }

        let visibleGlyphRange = layoutManager.glyphRange(
            forBoundingRect: textView.visibleRect,
            in: textContainer
        )
        if visibleGlyphRange.length == 0 { return }

        let firstCharIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
        var lineNumber = 1
        if firstCharIndex > 0 {
            let prefix = nsString.substring(to: firstCharIndex) as NSString
            var idx = 0
            while idx < prefix.length {
                if prefix.character(at: idx) == 0x0A { lineNumber += 1 }
                idx += 1
            }
        }

        layoutManager.enumerateLineFragments(forGlyphRange: visibleGlyphRange) { fragmentRect, _, _, glyphRange, _ in
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphRange.location)
            let isParagraphStart = charIndex == 0 || nsString.character(at: charIndex - 1) == 0x0A
            if isParagraphStart {
                self.drawNumber(lineNumber, atTextContainerY: fragmentRect.origin.y, textView: textView, attrs: attrs)
                lineNumber += 1
            }
        }

        if nsString.character(at: nsString.length - 1) == 0x0A {
            let totalGlyphs = layoutManager.numberOfGlyphs
            let visibleEnd = visibleGlyphRange.location + visibleGlyphRange.length
            if visibleEnd >= totalGlyphs {
                let extraRect = layoutManager.extraLineFragmentRect
                if extraRect.height > 0 {
                    drawNumber(lineNumber, atTextContainerY: extraRect.origin.y, textView: textView, attrs: attrs)
                }
            }
        }
    }

    private func drawNumber(_ number: Int,
                            atTextContainerY containerY: CGFloat,
                            textView: NSTextView,
                            attrs: [NSAttributedString.Key: Any]) {
        let label = "\(number)" as NSString
        let size = label.size(withAttributes: attrs)
        let inset = textView.textContainerInset

        let pointInTextView = NSPoint(x: 0, y: containerY + inset.height)
        let pointInRuler = convert(pointInTextView, from: textView)

        let lineHeight = (textView.layoutManager?.defaultLineHeight(for: textView.font ?? Self.numberFont)) ?? size.height
        let y = pointInRuler.y + (lineHeight - size.height) / 2
        let x = bounds.maxX - size.width - Self.trailingInset
        label.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
    }
}
#endif
