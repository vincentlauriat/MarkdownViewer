import SwiftUI

#if os(macOS)
import Sparkle
#endif

@main
struct MarkdownViewerApp: App {
    #if os(macOS)
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    #endif

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
            CommandGroup(replacing: .appInfo) {
                AboutMenuButton()
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterController.checkForUpdates(nil)
                }
            }
            CommandGroup(replacing: .help) {
                HelpMenuButton()
                WhatsNewMenuButton()
            }
            #endif
        }

        #if os(macOS)
        Window("About MarkdownViewer", id: "about") {
            AboutWindowView()
        }
        .windowResizability(.contentSize)

        Window("MarkdownViewer Help", id: "help") {
            HelpWindowView()
        }
        Window("What's New", id: "whats-new") {
            WhatsNewWindowView()
        }
        #endif
    }

    private func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}

#if os(macOS)
private struct AboutMenuButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("About MarkdownViewer") { openWindow(id: "about") }
    }
}

private struct HelpMenuButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("MarkdownViewer Help") { openWindow(id: "help") }
            .keyboardShortcut("?", modifiers: .command)
    }
}

private struct WhatsNewMenuButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("What's New…") { openWindow(id: "whats-new") }
    }
}
#endif

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
