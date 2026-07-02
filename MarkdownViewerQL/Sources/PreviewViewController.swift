import Cocoa
import os
import Quartz
import WebKit

private let log = Logger(subsystem: "com.vincent.MarkdownViewer.QL", category: "Preview")

class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {

    private var webView: WKWebView!
    private var bundleReady = false
    private var pendingMarkdown: String?
    private var pendingCompletion: ((Error?) -> Void)?

    // MARK: - View

    override func loadView() {
        webView = WKWebView(frame: .zero)
        webView.navigationDelegate = self
        view = webView

        guard let webRoot = Bundle.main.resourceURL?.appendingPathComponent("web") else { return }
        let indexURL = webRoot.appendingPathComponent("index.html")
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return }
        webView.loadFileURL(indexURL, allowingReadAccessTo: webRoot)
    }

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            handler(CocoaError(.fileReadUnknownStringEncoding))
            return
        }
        if bundleReady {
            render(content, completion: handler)
        } else {
            pendingMarkdown = content
            pendingCompletion = handler
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        bundleReady = true
        applyTheme()
        guard let md = pendingMarkdown, let handler = pendingCompletion else { return }
        pendingMarkdown = nil
        pendingCompletion = nil
        render(md, completion: handler)
    }

    // MARK: - Private

    private func applyTheme() {
        let isDark = view.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let theme = isDark ? "dark" : "light"
        webView.evaluateJavaScript("window.setTheme && window.setTheme('\(theme)')") { _, error in
            if let error {
                log.error("setTheme failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func render(_ markdown: String, completion: @escaping (Error?) -> Void) {
        let payload = WebPipeline.encodeForJS(markdown)
        webView.evaluateJavaScript("window.renderMarkdown(\(payload))") { _, error in
            if let error {
                log.error("renderMarkdown failed: \(error.localizedDescription, privacy: .public)")
            }
            completion(nil)
        }
    }
}
