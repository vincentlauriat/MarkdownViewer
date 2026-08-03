import Foundation

/// A heading extracted from raw markdown text.
///
/// `id` is the 0-based position of the heading in document order. It must stay in
/// lock-step with the `md-heading-N` ids that `web/render.js` assigns after
/// rendering: the outline menu is built in Swift but the scroll is performed in JS
/// purely by index number.
struct OutlineHeading: Identifiable {
    let id: Int
    let level: Int
    let title: String
}

/// Lightweight markdown heading parser, deliberately aligned with what markdown-it
/// renders as a *top-level* `<h1>`–`<h6>` (see `assignHeadingIds` in `render.js`):
/// frontmatter, fenced code, indented code and headings nested inside blockquotes
/// or list items are excluded on both sides so the indices never desync.
enum MarkdownOutline {
    // MARK: - Frontmatter

    /// Same pattern as `extractFrontmatter` in `web/render.js`. Built *without*
    /// `.anchorsMatchLines` so `^` stays start-of-string — a `---` thematic break in
    /// the middle of a document must never be mistaken for a frontmatter fence.
    private static let frontmatterRegex = try? NSRegularExpression(
        pattern: #"^---\s*\r?\n([\s\S]*?)\r?\n---\s*(?:\r?\n|$)"#,
        options: []
    )

    /// Drops a leading YAML frontmatter block, if any. Shared by the heading parser
    /// and the stats bar so both agree on what "the document body" is.
    static func stripFrontmatter(_ text: String) -> String {
        guard let regex = frontmatterRegex else { return text }
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: text, options: [], range: full) else { return text }
        return ns.substring(from: match.range.upperBound)
    }

    // MARK: - Headings

    static func headings(in text: String) -> [OutlineHeading] {
        let lines = stripFrontmatter(text)
            .components(separatedBy: "\n")
            .map { $0.hasSuffix("\r") ? String($0.dropLast()) : $0 }

        var headings: [OutlineHeading] = []
        var openFence: (marker: Character, length: Int)?
        var i = 0

        while i < lines.count {
            let line = lines[i]

            if let fence = openFence {
                if closesFence(line, marker: fence.marker, minLength: fence.length) { openFence = nil }
                i += 1
                continue
            }
            if isIndentedCode(line) {
                i += 1
                continue
            }
            if let fence = opensFence(line) {
                openFence = fence
                i += 1
                continue
            }
            if let atx = atxHeading(line) {
                headings.append(OutlineHeading(id: headings.count, level: atx.level, title: atx.title))
                i += 1
                continue
            }
            if i + 1 < lines.count,
               canStartSetext(line),
               let level = setextLevel(lines[i + 1])
            {
                headings.append(
                    OutlineHeading(
                        id: headings.count,
                        level: level,
                        title: line.trimmingCharacters(in: .whitespaces)
                    )
                )
                i += 2
                continue
            }
            i += 1
        }
        return headings
    }

    // MARK: - Line classification

    /// Everything past the leading spaces. Lines indented 4+ are filtered out
    /// beforehand by `isIndentedCode`, so this only ever drops 0–3 spaces.
    private static func withoutIndent(_ line: String) -> Substring {
        line.drop(while: { $0 == " " })
    }

    /// A tab or 4+ leading spaces starts an indented code block — a `#` there is
    /// literal text, not a heading.
    private static func isIndentedCode(_ line: String) -> Bool {
        var spaces = 0
        for ch in line {
            if ch == "\t" { return true }
            guard ch == " " else { return false }
            spaces += 1
            if spaces >= 4 { return true }
        }
        return false
    }

    private static func opensFence(_ line: String) -> (marker: Character, length: Int)? {
        let rest = withoutIndent(line)
        guard let marker = rest.first, marker == "`" || marker == "~" else { return nil }
        let run = rest.prefix(while: { $0 == marker })
        guard run.count >= 3 else { return nil }
        // CommonMark: a backtick fence's info string may not contain a backtick.
        if marker == "`", rest.dropFirst(run.count).contains("`") { return nil }
        return (marker, run.count)
    }

    private static func closesFence(_ line: String, marker: Character, minLength: Int) -> Bool {
        let rest = withoutIndent(line)
        let run = rest.prefix(while: { $0 == marker })
        guard run.count >= minLength else { return false }
        return rest.dropFirst(run.count).allSatisfy { $0 == " " || $0 == "\t" }
    }

    private static func atxHeading(_ line: String) -> (level: Int, title: String)? {
        let rest = withoutIndent(line)
        let hashes = rest.prefix(while: { $0 == "#" })
        guard (1 ... 6).contains(hashes.count) else { return nil }
        let after = rest.dropFirst(hashes.count)
        // `#hashtag` / `#5` are not headings: a space (or end of line) must follow.
        guard after.isEmpty || after.first == " " || after.first == "\t" else { return nil }
        return (hashes.count, trimmingClosingSequence(String(after)))
    }

    /// CommonMark allows an optional closing run of `#` (`### Title ###`).
    private static func trimmingClosingSequence(_ raw: String) -> String {
        let title = raw.trimmingCharacters(in: .whitespaces)
        let trailing = title.reversed().prefix(while: { $0 == "#" }).count
        guard trailing > 0 else { return title }
        let head = title.dropLast(trailing)
        guard head.isEmpty || head.last == " " || head.last == "\t" else { return title }
        return String(head).trimmingCharacters(in: .whitespaces)
    }

    /// A setext heading's text line: non-blank, and not something that would make
    /// markdown-it treat the following `---` / `===` as anything else.
    private static func canStartSetext(_ line: String) -> Bool {
        let rest = withoutIndent(line)
        guard !rest.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard setextLevel(line) == nil else { return false }
        guard let first = rest.first, first != ">" else { return false }
        if first == "-" || first == "*" || first == "+" {
            let next = rest.dropFirst().first
            if next == nil || next == " " || next == "\t" { return false }
        }
        let digits = rest.prefix(while: { $0.isNumber })
        if !digits.isEmpty {
            let afterDigits = rest.dropFirst(digits.count)
            if let delimiter = afterDigits.first, delimiter == "." || delimiter == ")" {
                let next = afterDigits.dropFirst().first
                if next == nil || next == " " || next == "\t" { return false }
            }
        }
        return true
    }

    /// A line made only of `=` (level 1) or only of `-` (level 2).
    private static func setextLevel(_ line: String) -> Int? {
        // An underline indented 4+ is a lazy paragraph continuation for markdown-it,
        // not a setext underline — counting it here would desync every later index.
        guard !isIndentedCode(line) else { return nil }
        var core = withoutIndent(line)
        while let last = core.last, last == " " || last == "\t" { core = core.dropLast() }
        guard let marker = core.first, marker == "=" || marker == "-" else { return nil }
        guard core.allSatisfy({ $0 == marker }) else { return nil }
        return marker == "=" ? 1 : 2
    }
}
