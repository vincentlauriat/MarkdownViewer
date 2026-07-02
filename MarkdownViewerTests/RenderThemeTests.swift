import XCTest
@testable import MarkdownViewer

final class RenderThemeTests: XCTestCase {

    func testAutoResolvesAgainstSystemAppearance() {
        XCTAssertEqual(RenderTheme.auto.cssName(systemIsDark: false), "light")
        XCTAssertEqual(RenderTheme.auto.cssName(systemIsDark: true), "dark")
    }

    func testForcedThemesIgnoreSystemAppearance() {
        for systemIsDark in [false, true] {
            XCTAssertEqual(RenderTheme.light.cssName(systemIsDark: systemIsDark), "light")
            XCTAssertEqual(RenderTheme.dark.cssName(systemIsDark: systemIsDark), "dark")
            XCTAssertEqual(RenderTheme.sepia.cssName(systemIsDark: systemIsDark), "sepia")
        }
    }

    func testAppearanceForcing() {
        XCTAssertNil(RenderTheme.auto.forcesDarkAppearance)
        XCTAssertEqual(RenderTheme.dark.forcesDarkAppearance, true)
        XCTAssertEqual(RenderTheme.light.forcesDarkAppearance, false)
        // Sepia is a light-based palette: media queries must resolve light.
        XCTAssertEqual(RenderTheme.sepia.forcesDarkAppearance, false)
    }

    func testRawValueRoundTripForSceneStorage() {
        for theme in RenderTheme.allCases {
            XCTAssertEqual(RenderTheme(rawValue: theme.rawValue), theme)
        }
        // Unknown persisted value falls back to nil (callers default to .auto).
        XCTAssertNil(RenderTheme(rawValue: "solarized"))
    }
}
