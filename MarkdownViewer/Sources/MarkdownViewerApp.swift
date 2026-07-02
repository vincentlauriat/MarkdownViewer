import SwiftUI

#if os(macOS)
import AppKit
import Sparkle
#endif

@main
struct MarkdownViewerApp: App {
    #if os(macOS)
    private let colorSpacePinner = WindowColorSpacePinner()

    private let updaterController: SPUStandardUpdaterController = {
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        // Stay prompt-based: Sparkle may *check* in the background, but it
        // must never download or install without user consent. Otherwise the
        // user's running app gets SIGKILLed mid-session and, if the swap
        // fails, restarted on the *old* version with no visible signal.
        controller.updater.automaticallyChecksForUpdates = true
        controller.updater.automaticallyDownloadsUpdates = false
        return controller
    }()
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
                Divider()
                Button("Zoom In") { post(.zoomIn) }
                    .keyboardShortcut("+", modifiers: .command)
                Button("Zoom Out") { post(.zoomOut) }
                    .keyboardShortcut("-", modifiers: .command)
                Button("Actual Size") { post(.zoomReset) }
                    .keyboardShortcut("0", modifiers: .command)
                Divider()
                Button("Toggle Current-Line Highlight") { post(.toggleCurrentLineHighlight) }
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
/// Pins every window of the app to plain sRGB as soon as it becomes key.
///
/// Workaround for the missing half-float CoreAnimation shaders on macOS 26.5 / 27
/// (see the matching per-WebView pinning in WebView.swift and
/// docs/apple-feedback-coreanimation-crash.md). The WebView-level pinning covered
/// the scroll-blit path, but on macOS 27 beta 26A5368g the same missing-shader
/// abort came back through a tone-mapped CG image draw (`CA::CG::fill_image`)
/// that can run for any window, before and outside the WebView pinning. A
/// markdown viewer has no need for EDR / wide gamut anywhere, so pinning every
/// window is free.
@MainActor
final class WindowColorSpacePinner {
    private var token: NSObjectProtocol?

    init() {
        token = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { note in
            Task { @MainActor in
                guard let window = note.object as? NSWindow, window.colorSpace != .sRGB else { return }
                window.colorSpace = .sRGB
            }
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

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
    static let zoomIn = Notification.Name("MarkdownViewer.zoomIn")
    static let zoomOut = Notification.Name("MarkdownViewer.zoomOut")
    static let zoomReset = Notification.Name("MarkdownViewer.zoomReset")
    static let toggleCurrentLineHighlight = Notification.Name("MarkdownViewer.toggleCurrentLineHighlight")
}
