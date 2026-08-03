import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @SceneStorage("viewMode") private var viewMode: ViewMode = .preview
    @SceneStorage("showFrontmatter") private var showFrontmatter: Bool = false
    @SceneStorage("zoomRatio") private var zoomRatio: Double = 1.0
    @SceneStorage("highlightCurrentLine") private var highlightCurrentLine: Bool = true
    @SceneStorage("renderTheme") private var renderThemeRaw: String = RenderTheme.auto.rawValue
    @State private var findQuery: String = ""
    @State private var showFind: Bool = false

    private static let zoomStep: Double = 0.1
    private static let zoomMin: Double = 0.5
    private static let zoomMax: Double = 3.0

    private var hasFrontmatter: Bool {
        WebPipeline.hasFrontmatter(document.text)
    }

    private var outlineHeadings: [OutlineHeading] {
        MarkdownOutline.headings(in: document.text)
    }

    private var renderTheme: RenderTheme {
        RenderTheme(rawValue: renderThemeRaw) ?? .auto
    }

    /// Sur iPhone le mode Split n'a pas de sens (largeur insuffisante) — on le filtre.
    private var availableModes: [ViewMode] {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return ViewMode.allCases.filter { $0 != .split }
        }
        #endif
        return ViewMode.allCases
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                content
                    .background(backgroundColor)
                if viewMode != .code {
                    Divider()
                    statsBar
                }
            }
            .frame(minWidth: 320, minHeight: 320)

            if showFind && viewMode != .code {
                FindBar(
                    query: $findQuery,
                    onClose: {
                        showFind = false
                        findQuery = ""
                    },
                    onSubmit: { forward in
                        post(.findRequest, userInfo: ["query": findQuery, "forward": forward])
                    }
                )
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showFind)
        .toolbar { toolbarContent }
        .onAppear {
            // S'assure qu'un mode invalide pour la plateforme retombe sur Preview
            if !availableModes.contains(viewMode) { viewMode = .preview }
            broadcastFrontmatter()
        }
        .onChange(of: showFrontmatter) { _ in broadcastFrontmatter() }
        .onReceive(NotificationCenter.default.publisher(for: .toggleFindBar)) { _ in
            if showFind { showFind = false; findQuery = "" } else { showFind = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleViewMode)) { _ in
            // Cycle uniquement parmi les modes disponibles pour la plateforme
            let modes = availableModes
            guard let i = modes.firstIndex(of: viewMode) else { viewMode = modes[0]; return }
            viewMode = modes[(i + 1) % modes.count]
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
            zoomRatio = min(Self.zoomMax, zoomRatio + Self.zoomStep)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
            zoomRatio = max(Self.zoomMin, zoomRatio - Self.zoomStep)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomReset)) { _ in
            zoomRatio = 1.0
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleCurrentLineHighlight)) { _ in
            highlightCurrentLine.toggle()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewMode {
        case .preview:
            WebView(markdown: document.text, zoom: zoomRatio, theme: renderTheme)
        case .code:
            MarkdownEditor(text: $document.text, highlightCurrentLine: highlightCurrentLine)
        case .split:
            #if os(macOS)
            HSplitView {
                MarkdownEditor(text: $document.text, highlightCurrentLine: highlightCurrentLine)
                    .frame(minWidth: 240)
                WebView(markdown: document.text, zoom: zoomRatio, theme: renderTheme)
                    .frame(minWidth: 240)
            }
            #else
            // Fallback iPad (HSplitView est macOS-only) : HStack équilibré avec un divider visuel
            HStack(spacing: 0) {
                MarkdownEditor(text: $document.text, highlightCurrentLine: highlightCurrentLine)
                Divider()
                WebView(markdown: document.text, zoom: zoomRatio, theme: renderTheme)
            }
            #endif
        }
    }

    /// Word count and reading time for the document body (frontmatter excluded, so
    /// YAML keys don't inflate the count).
    private var statsBar: some View {
        let wordCount = MarkdownOutline
            .stripFrontmatter(document.text)
            .split { $0.isWhitespace || $0.isNewline }
            .count
        let minutes = max(1, Int((Double(wordCount) / 200.0).rounded()))
        return HStack(spacing: 12) {
            Label("\(wordCount) words", systemImage: "text.word.spacing")
            Label("\(minutes) min read", systemImage: "clock")
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Picker("View Mode", selection: $viewMode) {
                ForEach(availableModes) { mode in
                    Image(systemName: mode.systemImage)
                        .help(mode.label)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: CGFloat(availableModes.count) * 50)
        }
        if !outlineHeadings.isEmpty {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(outlineHeadings) { heading in
                        Button(outlineLabel(for: heading)) {
                            post(.scrollToHeadingRequest, userInfo: ["index": heading.id])
                        }
                    }
                } label: {
                    Image(systemName: "list.bullet.indent")
                }
                .help("Document outline")
                // No WebView exists in the Code hierarchy — the notification would
                // land nowhere.
                .disabled(viewMode == .code)
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Picker("Theme", selection: $renderThemeRaw) {
                    ForEach(RenderTheme.allCases) { theme in
                        Text(theme.label).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: renderTheme == .auto ? "paintpalette" : "paintpalette.fill")
            }
            .help("Preview theme")
            .disabled(viewMode == .code)
        }
        ToolbarItem(placement: .primaryAction) {
            Button {
                showFrontmatter.toggle()
            } label: {
                Image(systemName: showFrontmatter ? "tag.fill" : "tag")
            }
            .help(showFrontmatter ? "Hide YAML frontmatter" : "Show YAML frontmatter")
            .disabled(!hasFrontmatter)
            .keyboardShortcut("y", modifiers: [.command, .shift])
        }
        #if os(macOS)
        ToolbarItem(placement: .primaryAction) {
            Button {
                post(.exportPDFActiveDocument)
            } label: {
                Image(systemName: "arrow.down.doc")
            }
            .help("Export as PDF…")
            // No WebView exists in the Code hierarchy — nothing to export from.
            .disabled(viewMode == .code)
        }
        #endif
    }

    /// Indented by heading level; an empty ATX title (`### ###`) would otherwise
    /// render as an invisible menu row.
    private func outlineLabel(for heading: OutlineHeading) -> String {
        let indent = String(repeating: "    ", count: max(0, heading.level - 1))
        return indent + (heading.title.isEmpty ? "—" : heading.title)
    }

    private var backgroundColor: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    private func post(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }

    private func broadcastFrontmatter() {
        post(.setFrontmatterVisibility, userInfo: ["visible": showFrontmatter])
    }
}
