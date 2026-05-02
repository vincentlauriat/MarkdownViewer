import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @SceneStorage("viewMode") private var viewMode: ViewMode = .preview
    @SceneStorage("showFrontmatter") private var showFrontmatter: Bool = false
    @State private var findQuery: String = ""
    @State private var showFind: Bool = false

    private var hasFrontmatter: Bool {
        let trimmed = document.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("---") else { return false }
        // Cherche le délimiteur fermant `---` sur sa propre ligne
        let lines = document.text.components(separatedBy: "\n")
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return false }
        for line in lines.dropFirst() {
            if line.trimmingCharacters(in: .whitespaces) == "---" { return true }
        }
        return false
    }

    var body: some View {
        ZStack(alignment: .top) {
            content
                .frame(minWidth: 720, minHeight: 480)
                .background(Color(nsColor: .textBackgroundColor))

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
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("View Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Image(systemName: mode.systemImage)
                            .help(mode.label)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
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
        }
        .onAppear { broadcastFrontmatter() }
        .onChange(of: showFrontmatter) { _ in broadcastFrontmatter() }
        .onReceive(NotificationCenter.default.publisher(for: .toggleFindBar)) { _ in
            if showFind { showFind = false; findQuery = "" } else { showFind = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleViewMode)) { _ in
            viewMode = viewMode.cycled()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewMode {
        case .preview:
            WebView(markdown: document.text)
        case .code:
            MarkdownEditor(text: $document.text)
        case .split:
            HSplitView {
                MarkdownEditor(text: $document.text)
                    .frame(minWidth: 240)
                WebView(markdown: document.text)
                    .frame(minWidth: 240)
            }
        }
    }

    private func post(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
    }

    private func broadcastFrontmatter() {
        post(.setFrontmatterVisibility, userInfo: ["visible": showFrontmatter])
    }
}
