import AppKit
import os
import SwiftUI
import WebKit

private let log = Logger(subsystem: "com.vincent.MarkdownViewer", category: "WebView")

struct WebView: NSViewRepresentable {
    let markdown: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsBackForwardNavigationGestures = false

        context.coordinator.webView = webView
        context.coordinator.observeAppearance()
        context.coordinator.observeReloadCommand()
        loadBundle(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.documentMarkdown = markdown
        context.coordinator.flush()
    }

    private func loadBundle(into webView: WKWebView) {
        guard let resources = Bundle.main.resourceURL else { return }
        let webRoot = resources.appendingPathComponent("web", isDirectory: true)
        let indexURL = webRoot.appendingPathComponent("index.html")
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return }
        webView.loadFileURL(indexURL, allowingReadAccessTo: webRoot)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        /// Texte transmis par SwiftUI (ouverture initiale + Cmd+R).
        var documentMarkdown: String = ""
        /// Texte le plus récent (relu depuis le disque par le file watcher).
        private var liveMarkdown: String?
        private var bundleReady = false
        private var appearanceObservation: NSKeyValueObservation?
        private var observers: [NSObjectProtocol] = []
        private var fileWatcher: FileWatcher?
        private var lastFindQuery: String = ""

        func observeAppearance() {
            applyTheme()
            appearanceObservation = NSApp?.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.applyTheme() }
            }
        }

        func observeReloadCommand() {
            observe(.reloadActiveDocument) { [weak self] _ in self?.reloadFromDisk() }
            observe(.printActiveDocument) { [weak self] _ in self?.printDocument() }
            observe(.findRequest) { [weak self] note in
                guard let info = note.userInfo,
                      let query = info["query"] as? String,
                      let forward = info["forward"] as? Bool
                else { return }
                self?.runFind(query: query, forward: forward)
            }
            observe(.findNext) { [weak self] _ in self?.runFind(query: nil, forward: true) }
            observe(.findPrevious) { [weak self] _ in self?.runFind(query: nil, forward: false) }
        }

        private func observe(_ name: Notification.Name, action: @escaping @MainActor @Sendable (Notification) -> Void) {
            let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { note in
                Task { @MainActor in action(note) }
            }
            observers.append(token)
        }

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            bundleReady = true
            applyTheme()
            flush()
            attachFileWatcherIfPossible()
        }

        func flush() {
            guard bundleReady, let webView else { return }
            let payload = encodeForJS(liveMarkdown ?? documentMarkdown)
            webView.evaluateJavaScript("window.renderMarkdown(\(payload))", completionHandler: nil)
        }

        // MARK: - Live reload

        private func attachFileWatcherIfPossible() {
            // representedURL n'est pas forcément posée immédiatement après didFinish,
            // on retente quelques fois (DocumentGroup la pose après l'attachement à la fenêtre).
            tryAttach(retriesLeft: 10)
        }

        private func tryAttach(retriesLeft: Int) {
            guard let webView, fileWatcher == nil else { return }
            if let url = webView.window?.representedURL {
                log.info("attach: representedURL = \(url.lastPathComponent, privacy: .public)")
                fileWatcher = FileWatcher(url: url) { [weak self] in
                    self?.reloadFromDisk()
                }
                return
            }
            guard retriesLeft > 0 else {
                log.error("attach: representedURL still nil after retries — live reload disabled for this window")
                return
            }
            log.debug("attach: representedURL nil, retries left=\(retriesLeft)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.tryAttach(retriesLeft: retriesLeft - 1)
            }
        }

        private func reloadFromDisk() {
            guard let url = fileWatcher?.url ?? webView?.window?.representedURL else {
                // Pas d'URL connue — on retombe sur le contenu fourni par SwiftUI.
                liveMarkdown = nil
                flush()
                return
            }
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                liveMarkdown = text
                log.info("reload OK (\(text.count) chars) for \(url.lastPathComponent, privacy: .public)")
                flush()
            } catch {
                log.error("reload failed for \(url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        // MARK: - Thème

        private func applyTheme() {
            guard bundleReady, let webView else { return }
            let isDark = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let theme = isDark ? "dark" : "light"
            webView.evaluateJavaScript("window.setTheme && window.setTheme('\(theme)')", completionHandler: nil)
        }

        // MARK: - Print

        private func printDocument() {
            guard let webView, isActiveWebView() else { return }
            let info = NSPrintInfo.shared
            info.topMargin = 36; info.bottomMargin = 36
            info.leftMargin = 36; info.rightMargin = 36
            let op = webView.printOperation(with: info)
            op.view?.frame = NSRect(x: 0, y: 0, width: 800, height: 1100)
            if let window = webView.window {
                op.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
            } else {
                op.run()
            }
        }

        // MARK: - Find

        private func runFind(query: String?, forward: Bool) {
            guard let webView, isActiveWebView() else { return }
            let q = query ?? lastFindQuery
            guard !q.isEmpty else { return }
            lastFindQuery = q
            let config = WKFindConfiguration()
            config.backwards = !forward
            config.caseSensitive = false
            config.wraps = true
            webView.find(q, configuration: config) { result in
                if !result.matchFound {
                    log.debug("find: no match for \(q, privacy: .public)")
                }
            }
        }

        private func isActiveWebView() -> Bool {
            webView?.window?.isKeyWindow == true
        }

        // MARK: - Liens externes

        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url
            {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        // MARK: - Helpers

        private func encodeForJS(_ str: String) -> String {
            guard
                let data = try? JSONSerialization.data(withJSONObject: str, options: [.fragmentsAllowed]),
                let result = String(data: data, encoding: .utf8)
            else {
                return "\"\""
            }
            return result
        }

        deinit {
            for token in observers {
                NotificationCenter.default.removeObserver(token)
            }
        }
    }
}
