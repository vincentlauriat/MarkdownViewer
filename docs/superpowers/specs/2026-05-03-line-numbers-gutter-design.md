# Line numbers gutter — design

**Date**: 2026-05-03
**Scope**: macOS only — modes Source (`.code`) and Split
**Out of scope**: iOS / iPadOS, toggle on/off, current-line highlight

## Goal

Display line numbers in a left margin (gutter) inside the `MarkdownEditor` whenever it is shown on macOS, similarly to the gutter in Xcode or VS Code.

## Approach

Subclass AppKit's `NSRulerView` and attach it as the `verticalRulerView` of the `NSScrollView` that already wraps the `NSTextView`. AppKit handles scroll synchronization, layout-change events, and clipping for free. This is the same mechanism Xcode uses.

Alternative considered and rejected: a SwiftUI overlay aligned manually with the scroll view. Manually keeping a side view in sync with `NSScrollView` content offsets, line wrapping and resize is fragile and offers no benefit over the native approach.

## Architecture

| Element | Decision |
|---|---|
| New file | `MarkdownViewer/Sources/LineNumberRulerView.swift`, gated by `#if os(macOS)` |
| Class | `final class LineNumberRulerView: NSRulerView` |
| Wiring | In `MarkdownEditor.makeNSView()`, after the `NSScrollView` is created: instantiate the ruler, set `scroll.verticalRulerView = ruler`, then `scroll.hasVerticalRuler = true` and `scroll.rulersVisible = true` |
| Live updates | Observe `NSText.didChangeNotification` on the `NSTextView` and `NSView.frameDidChangeNotification` on its content view → call `needsDisplay = true` on the ruler |
| Cleanup | Notification observers removed in `deinit` |

The ruler keeps a weak reference to the `NSTextView` it numbers. The existing `Coordinator` pattern is reused — the ruler does not need to be a delegate.

## Visual specification

| Property | Value |
|---|---|
| Width | Dynamic. `ceil(log10(max(1, lineCount + 1)))` digits, plus 12 pt of horizontal padding. Minimum 28 pt (≤ 9 lines), grows in steps as the document grows |
| Font | `NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)` |
| Number color | `NSColor.tertiaryLabelColor` (auto-adapts to dark mode) |
| Background | `NSColor.textBackgroundColor` (matches editor — no visible band) |
| Right separator | 1 px vertical line, `NSColor.quaternaryLabelColor` |
| Number alignment | Right-aligned, 6 pt padding from the right edge |
| Vertical alignment | Numbers align with the **first visual line** of each paragraph. Soft-wrapped continuation lines do not get a number (Xcode/VS Code convention) |

## Drawing algorithm — `drawHashMarksAndLabels(in rect: NSRect)`

1. Guard on `clientView as? NSTextView`, its `layoutManager`, and `textContainer`.
2. Compute the visible glyph range using `layoutManager.glyphRange(forBoundingRect: rect, in: textContainer)`.
3. Translate that to a character range and count newlines from offset 0 up to its lower bound to determine the starting line number. (Acceptable cost for typical Markdown documents — under a millisecond for tens of thousands of characters.)
4. Walk the visible glyph range with `layoutManager.enumerateLineFragments(forGlyphRange:)`. For each fragment:
   - Compute the character at `fragment.location`.
   - If that character starts a paragraph (i.e. the character before is `\n` or it is the document start), draw the current line number; otherwise this is a soft-wrap continuation — skip.
   - Y position: `fragment.rect.origin.y` translated into ruler coordinates via the text container's origin offset.
5. Draw the trailing separator line at `bounds.maxX - 1`.

Edge case: an empty document. `numberOfLines == 0` → display "1" at `textContainerInset.height`.

## Width recomputation

`ruleThickness` is recomputed when:
- The text changes (`textDidChange`), based on the new line count.
- The font of the text view changes (theoretically not in current code, but cheap to handle).

`invalidateHashMarks()` is called whenever the thickness might change, so AppKit re-lays out the ruler.

## Files touched

| File | Change |
|---|---|
| `MarkdownViewer/Sources/LineNumberRulerView.swift` | **New file** — ~80–100 lines |
| `MarkdownViewer/Sources/MarkdownEditor.swift` | Wire the ruler into `makeNSView`, dispose observers in coordinator. iOS path untouched |

No new dependencies. No `project.yml` change (XcodeGen picks up the new Swift file automatically since `Sources/**/*.swift` is globbed).

## Test plan (manual)

- [ ] Open `sample.md`, switch to **Source** → numbers visible, aligned with text baseline
- [ ] Switch to **Split** → ruler visible on the editor pane only, not on preview
- [ ] Open a 500+ line document → ruler width grows automatically, no clipping
- [ ] Type into the editor → numbers update at every keystroke without flicker
- [ ] Resize the window narrower until lines soft-wrap → wrapped continuation lines have no number
- [ ] Toggle system appearance light ↔ dark → number color and separator adapt
- [ ] Cmd+Z / Cmd+Shift+Z → numbers track undo state correctly
- [ ] Open an empty document → "1" displayed
- [ ] Build iOS target → still compiles (the `#if os(macOS)` gate excludes the new file from iOS)

## Acceptance criteria

1. `xcodebuild` macOS target builds cleanly.
2. `xcodebuild` iOS target still builds cleanly.
3. The eight first manual checks above all pass.
4. No new warnings introduced.
