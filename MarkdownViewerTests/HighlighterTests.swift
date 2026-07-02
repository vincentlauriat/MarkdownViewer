import AppKit
import XCTest
@testable import MarkdownViewer

final class HighlighterTests: XCTestCase {

    private let baseFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    private func highlighted(_ markdown: String) -> NSTextStorage {
        let storage = NSTextStorage(string: markdown)
        Highlighter.apply(to: storage, baseFont: baseFont)
        return storage
    }

    private func font(in storage: NSTextStorage, at location: Int) -> NSFont? {
        storage.attribute(.font, at: location, effectiveRange: nil) as? NSFont
    }

    private func isBold(_ font: NSFont?) -> Bool {
        font?.fontDescriptor.symbolicTraits.contains(.bold) ?? false
    }

    func testPlainTextKeepsBaseFont() {
        let storage = highlighted("just plain text")
        XCTAssertEqual(font(in: storage, at: 0), baseFont)
    }

    func testHeadingIsBoldAndLarger() {
        let storage = highlighted("# Title\nbody")
        let headingFont = font(in: storage, at: 0)
        XCTAssertTrue(isBold(headingFont))
        // H1: max(13, 22 - 1 × 1.2) = 20.8
        XCTAssertEqual(headingFont?.pointSize ?? 0, 20.8, accuracy: 0.01)
        // The body below the heading keeps the base font
        let bodyLocation = ("# Title\n" as NSString).length
        XCTAssertEqual(font(in: storage, at: bodyLocation), baseFont)
    }

    func testDeepHeadingClampsAt13() {
        let storage = highlighted("###### Small heading")
        // H6: max(13, 22 - 6 × 1.2) = 14.8
        XCTAssertEqual(font(in: storage, at: 0)?.pointSize ?? 0, 14.8, accuracy: 0.01)
    }

    func testBoldSpanUsesBoldFont() {
        let text = "some **bold** words"
        let storage = highlighted(text)
        let boldLocation = (text as NSString).range(of: "**bold**").location
        XCTAssertTrue(isBold(font(in: storage, at: boldLocation)))
        XCTAssertFalse(isBold(font(in: storage, at: 0)))
    }

    func testInlineCodeIsPinkWithBackground() {
        let text = "run `make build` now"
        let storage = highlighted(text)
        let codeLocation = (text as NSString).range(of: "`make build`").location
        let fg = storage.attribute(.foregroundColor, at: codeLocation, effectiveRange: nil) as? NSColor
        XCTAssertEqual(fg, .systemPink)
        XCTAssertNotNil(storage.attribute(.backgroundColor, at: codeLocation, effectiveRange: nil))
    }

    func testFencedCodeBlockIsPink() {
        let text = "before\n```\nlet x = 1\n```\nafter"
        let storage = highlighted(text)
        let codeLocation = (text as NSString).range(of: "let x = 1").location
        let fg = storage.attribute(.foregroundColor, at: codeLocation, effectiveRange: nil) as? NSColor
        XCTAssertEqual(fg, .systemPink)
    }

    func testLinkGetsLinkColor() {
        let text = "see [docs](https://example.com) here"
        let storage = highlighted(text)
        let linkLocation = (text as NSString).range(of: "[docs]").location
        let linkColor = storage.attribute(.foregroundColor, at: linkLocation, effectiveRange: nil) as? NSColor
        let plainColor = storage.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        XCTAssertNotEqual(linkColor, plainColor)
    }

    func testEmptyStorageDoesNotCrash() {
        let storage = highlighted("")
        XCTAssertEqual(storage.length, 0)
    }

    func testNilStorageDoesNotCrash() {
        Highlighter.apply(to: nil, baseFont: baseFont)
    }
}
