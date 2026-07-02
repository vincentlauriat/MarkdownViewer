import Foundation
#if os(macOS)
import AppKit
#endif

/// Helpers shared between the main app's `WebView` and the Quick Look
/// extension's `PreviewViewController` — both drive the same bundled `web/`
/// rendering pipeline. Compiled into every target (see project.yml).
enum WebPipeline {
    /// Encode a string as a JSON literal safe to inline in `evaluateJavaScript`.
    static func encodeForJS(_ str: String) -> String {
        guard
            let data = try? JSONSerialization.data(withJSONObject: str, options: [.fragmentsAllowed]),
            let result = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }
        return result
    }

    /// True when the document starts with a closed YAML frontmatter block:
    /// `---` on the very first line, closed by another `---` line.
    static func hasFrontmatter(_ text: String) -> Bool {
        let lines = text.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return false }
        for line in lines.dropFirst() where line.trimmingCharacters(in: .whitespaces) == "---" {
            return true
        }
        return false
    }

    #if os(macOS)
    /// Dark page background — must match the CSS in `web/index.html`
    /// (`html[data-theme="dark"] { background: #0d1117 }`).
    static let darkBackground = NSColor(srgbRed: 13 / 255, green: 17 / 255, blue: 23 / 255, alpha: 1)

    /// Sepia page background — must match the CSS in `web/index.html`
    /// (`html[data-theme="sepia"] { background: #f4ecd8 }`).
    static let sepiaBackground = NSColor(srgbRed: 244 / 255, green: 236 / 255, blue: 216 / 255, alpha: 1)
    #endif
}
