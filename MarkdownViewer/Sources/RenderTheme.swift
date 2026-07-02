import Foundation

/// Rendering theme for the markdown preview. `auto` follows the system
/// appearance (the pre-v0.9 behaviour); the others force a fixed palette
/// regardless of the system setting.
enum RenderTheme: String, CaseIterable, Identifiable {
    case auto
    case light
    case dark
    case sepia

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto: "Auto (System)"
        case .light: "GitHub Light"
        case .dark: "GitHub Dark"
        case .sepia: "Sepia"
        }
    }

    /// Theme name passed to `window.setTheme()` in render.js.
    /// `systemIsDark` resolves `.auto` against the current appearance.
    func cssName(systemIsDark: Bool) -> String {
        switch self {
        case .auto: systemIsDark ? "dark" : "light"
        case .light: "light"
        case .dark: "dark"
        case .sepia: "sepia"
        }
    }

    /// Appearance to force on the web view so `prefers-color-scheme` media
    /// queries (github-markdown.css palettes) agree with a non-auto theme.
    /// `nil` = follow the system.
    var forcesDarkAppearance: Bool? {
        switch self {
        case .auto: nil
        case .dark: true
        case .light, .sepia: false
        }
    }
}
