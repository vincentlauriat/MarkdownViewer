import SwiftUI

@main
struct MarkdownViewerApp: App {
    init() {
        #if os(macOS)
        UpdateChecker.checkOnLaunchIfNeeded()
        #endif
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Reload from Disk") { post(.reloadActiveDocument) }
                    .keyboardShortcut("r", modifiers: .command)
                Divider()
                Button("Toggle View Mode") { post(.toggleViewMode) }
                    .keyboardShortcut("/", modifiers: .command)
            }

            CommandGroup(replacing: .printItem) {
                Button("Print…") { post(.printActiveDocument) }
                    .keyboardShortcut("p", modifiers: .command)
            }

            CommandGroup(replacing: .textEditing) {
                Button("Find…") { post(.toggleFindBar) }
                    .keyboardShortcut("f", modifiers: .command)
                Button("Find Next") { post(.findNext) }
                    .keyboardShortcut("g", modifiers: .command)
                Button("Find Previous") { post(.findPrevious) }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
            }

            #if os(macOS)
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { UpdateChecker.checkFromMenu() }
            }
            #endif
        }
    }

    private func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}

extension Notification.Name {
    static let reloadActiveDocument = Notification.Name("MarkdownViewer.reloadActiveDocument")
    static let printActiveDocument = Notification.Name("MarkdownViewer.printActiveDocument")
    static let toggleFindBar = Notification.Name("MarkdownViewer.toggleFindBar")
    static let findRequest = Notification.Name("MarkdownViewer.findRequest")
    static let findNext = Notification.Name("MarkdownViewer.findNext")
    static let findPrevious = Notification.Name("MarkdownViewer.findPrevious")
    static let toggleViewMode = Notification.Name("MarkdownViewer.toggleViewMode")
    static let setFrontmatterVisibility = Notification.Name("MarkdownViewer.setFrontmatterVisibility")
}
