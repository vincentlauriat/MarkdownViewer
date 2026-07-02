import XCTest
@testable import MarkdownViewer

final class WebPipelineTests: XCTestCase {

    // MARK: - encodeForJS

    func testEncodeSimpleString() {
        XCTAssertEqual(WebPipeline.encodeForJS("hello"), "\"hello\"")
    }

    func testEncodeEmptyString() {
        XCTAssertEqual(WebPipeline.encodeForJS(""), "\"\"")
    }

    func testEncodeEscapesQuotesAndBackslashes() {
        let encoded = WebPipeline.encodeForJS(#"say "hi" \ bye"#)
        XCTAssertEqual(encoded, #""say \"hi\" \\ bye""#)
    }

    func testEncodeEscapesNewlines() {
        let encoded = WebPipeline.encodeForJS("line1\nline2")
        XCTAssertEqual(encoded, #""line1\nline2""#)
        XCTAssertFalse(encoded.contains("\n"), "raw newlines would break the JS injection")
    }

    func testEncodePreservesUnicode() {
        let encoded = WebPipeline.encodeForJS("héllo 🚀 中文")
        XCTAssertTrue(encoded.contains("héllo"))
        XCTAssertTrue(encoded.contains("🚀"))
        XCTAssertTrue(encoded.contains("中文"))
    }

    func testEncodedPayloadRoundTripsThroughJSONDecoding() throws {
        let original = "# Title\n\n```swift\nlet x = \"1\"\n```\n"
        let encoded = WebPipeline.encodeForJS(original)
        let decoded = try JSONSerialization.jsonObject(
            with: Data(encoded.utf8), options: [.fragmentsAllowed]
        ) as? String
        XCTAssertEqual(decoded, original)
    }

    // MARK: - hasFrontmatter

    func testDetectsClosedFrontmatter() {
        XCTAssertTrue(WebPipeline.hasFrontmatter("---\ntitle: Test\n---\n# Body"))
    }

    func testDetectsFrontmatterWithTrailingSpacesOnDelimiters() {
        XCTAssertTrue(WebPipeline.hasFrontmatter("--- \ntitle: Test\n  ---  \nbody"))
    }

    func testRejectsPlainDocument() {
        XCTAssertFalse(WebPipeline.hasFrontmatter("# Just a heading\n\nSome text."))
    }

    func testRejectsUnclosedFrontmatter() {
        XCTAssertFalse(WebPipeline.hasFrontmatter("---\ntitle: Test\nno closing delimiter"))
    }

    func testRejectsFrontmatterNotOnFirstLine() {
        XCTAssertFalse(WebPipeline.hasFrontmatter("\n---\ntitle: Test\n---\n"))
    }

    func testRejectsEmptyDocument() {
        XCTAssertFalse(WebPipeline.hasFrontmatter(""))
    }

    func testHorizontalRuleAloneIsNotFrontmatter() {
        XCTAssertFalse(WebPipeline.hasFrontmatter("some text\n\n---\n\nmore text"))
    }
}
