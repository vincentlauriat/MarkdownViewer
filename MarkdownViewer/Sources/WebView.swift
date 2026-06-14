import os
import SwiftUI
import WebKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

private let log = Logger(subsystem: "com.vincent.MarkdownViewer", category: "WebView")

#if os(macOS)
struct WebView: NSViewRepresentable {
    let markdown: String
    var zoom: Double = 1.0

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = configureWebView(context: context)
        webView.pageZoom = CGFloat(zoom)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.documentMarkdown = markdown
        context.coordinator.flush()
        if abs(webView.pageZoom - CGFloat(zoom)) > 0.001 {
            webView.pageZoom = CGFloat(zoom)
        }
    }
}
#elseif os(iOS)
struct WebView: UIViewRepresentable {
    let markdown: String
    var zoom: Double = 1.0  // ignoré sur iOS (WKWebView.pageZoom est macOS-only)

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        configureWebView(context: context)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.documentMarkdown = markdown
        context.coordinator.flush()
    }
}
#endif

extension WebView {
    fileprivate func configureWebView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        #if os(macOS)
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        #if os(macOS)
        // --- Crash workaround (macOS 27.0 beta) ---
        // CoreAnimation aborts during scroll with "Function image_rect_blit_frag_lph
        // was not found in the library". The "_lph" variant is the half-float /
        // extended-range (EDR / wide-gamut) image-blit shader, which is missing from
        // QuartzCore's Metal library on this OS seed. Forcing the WebView layer to
        // plain 8-bit sRGB contents (no EDR, no wide gamut) routes compositing to the
        // 8-bit blit shader, which is present. The window colour space is also pinned
        // to sRGB once the view is in a window (see Coordinator.pinSRGBColorSpace).
        webView.allowsBackForwardNavigationGestures = false
        webView.layer?.contentsFormat = .RGBA8Uint
        // Opaque layer (drawsBackground defaults to true); solid background comes from
        // the page CSS, underPageBackgroundColor fills the overscroll area on-theme.
        if #available(macOS 12.0, *) {
            let isDark = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            webView.underPageBackgroundColor = isDark
                ? NSColor(srgbRed: 13 / 255, green: 17 / 255, blue: 23 / 255, alpha: 1)
                : .white
        }
        #else
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        #endif

        context.coordinator.webView = webView
        context.coordinator.observeAppearance()
        context.coordinator.observeReloadCommand()
        loadBundle(into: webView)
        return webView
    }

    fileprivate func loadBundle(into webView: WKWebView) {
        guard let resources = Bundle.main.resourceURL else { return }
        let webRoot = resources.appendingPathComponent("web", isDirectory: true)
        let indexURL = webRoot.appendingPathComponent("index.html")
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return }
        webView.loadFileURL(indexURL, allowingReadAccessTo: webRoot)
    }
}

extension WebView {
    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var documentMarkdown: String = ""
        private var liveMarkdown: String?
        private var bundleReady = false
        var lastFrontmatterVisible: Bool = false
        private var observers: [NSObjectProtocol] = []
        private var fileWatcher: FileWatcher?
        private var lastFindQuery: String = ""
        #if os(macOS)
        private var appearanceObservation: NSKeyValueObservation?
        #endif

        // MARK: - Theme

        func observeAppearance() {
            applyTheme()
            #if os(macOS)
            appearanceObservation = NSApp?.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.applyTheme() }
            }
            #endif
        }

        private func applyTheme() {
            guard bundleReady, let webView else { return }
            let isDark: Bool = {
                #if os(macOS)
                return NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                #elseif os(iOS)
                return webView.traitCollection.userInterfaceStyle == .dark
                #endif
            }()
            let theme = isDark ? "dark" : "light"
            webView.evaluateJavaScript("window.setTheme && window.setTheme('\(theme)')", completionHandler: nil)
            #if os(macOS)
            // Match the opaque overscroll area to the page CSS background
            // (#ffffff light / #0d1117 dark) so the rubber-band edge and any
            // pre-paint frame stay on-theme.
            if #available(macOS 12.0, *) {
                webView.underPageBackgroundColor = isDark
                    ? NSColor(srgbRed: 13 / 255, green: 17 / 255, blue: 23 / 255, alpha: 1)
                    : .white
            }
            #endif
        }

        // MARK: - Notifications

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
            observe(.setFrontmatterVisibility) { [weak self] note in
                let visible = (note.userInfo?["visible"] as? Bool) ?? true
                self?.applyFrontmatterVisibility(visible)
            }
        }

        private func observe(_ name: Notification.Name, action: @escaping @MainActor @Sendable (Notification) -> Void) {
            let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { note in
                Task { @MainActor in action(note) }
            }
            observers.append(token)
        }

        // MARK: - Render

        func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
            bundleReady = true
            applyTheme()
            flush()
            attachFileWatcherIfPossible()
        }

        func flush() {
            guard bundleReady, let webView else { return }
            let payload = encodeForJS(liveMarkdown ?? documentMarkdown)
            let visible = lastFrontmatterVisible ? "true" : "false"
            webView.evaluateJavaScript(
                "window.setFrontmatterVisible && window.setFrontmatterVisible(\(visible)); window.renderMarkdown(\(payload))",
                completionHandler: nil
            )
        }

        // MARK: - Live reload

        private func attachFileWatcherIfPossible() {
            #if os(macOS)
            tryAttach(retriesLeft: 10)
            #endif
        }

        #if os(macOS)
        // Pin the document window to plain sRGB so CoreAnimation never requests the
        // half-float/EDR image-blit shader (image_rect_blit_frag_lph) that is missing
        // from QuartzCore's Metal library on the macOS 27.0 beta seed and aborts the
        // app during scroll. A markdown viewer has no need for EDR / wide gamut.
        private var didPinColorSpace = false
        private func pinSRGBColorSpace() {
            guard !didPinColorSpace, let window = webView?.window else { return }
            window.colorSpace = .sRGB
            didPinColorSpace = true
        }

        private func tryAttach(retriesLeft: Int) {
            guard let webView, fileWatcher == nil else { return }
            pinSRGBColorSpace()
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.tryAttach(retriesLeft: retriesLeft - 1)
            }
        }
        #endif

        private func reloadFromDisk() {
            #if os(macOS)
            guard let url = fileWatcher?.url ?? webView?.window?.representedURL else {
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
            #endif
        }

        // MARK: - Print

        private func printDocument() {
            guard let webView, isActiveWebView() else { return }
            #if os(macOS)
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
            #elseif os(iOS)
            let formatter = webView.viewPrintFormatter()
            let printController = UIPrintInteractionController.shared
            printController.printFormatter = formatter
            printController.present(animated: true, completionHandler: nil)
            #endif
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
            #if os(macOS)
            return webView?.window?.isKeyWindow == true
            #else
            return true
            #endif
        }

        // MARK: - Frontmatter

        private func applyFrontmatterVisibility(_ visible: Bool) {
            lastFrontmatterVisible = visible
            guard bundleReady, let webView else { return }
            webView.evaluateJavaScript("window.setFrontmatterVisible && window.setFrontmatterVisible(\(visible ? "true" : "false"))", completionHandler: nil)
        }

        // MARK: - External links

        func webView(
            _: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url
            {
                #if os(macOS)
                NSWorkspace.shared.open(url)
                #elseif os(iOS)
                UIApplication.shared.open(url)
                #endif
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
