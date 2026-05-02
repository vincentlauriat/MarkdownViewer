import SwiftUI

enum ViewMode: String, CaseIterable, Identifiable {
    case preview
    case split
    case code

    var id: String { rawValue }

    var label: String {
        switch self {
        case .preview: "Preview"
        case .split: "Split"
        case .code: "Source"
        }
    }

    var systemImage: String {
        switch self {
        case .preview: "eye"
        case .split: "rectangle.split.2x1"
        case .code: "chevron.left.forwardslash.chevron.right"
        }
    }

    func cycled() -> ViewMode {
        let all = ViewMode.allCases
        guard let i = all.firstIndex(of: self) else { return .preview }
        return all[(i + 1) % all.count]
    }
}
