import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {

    private var webView: WKWebView!
    private var bundleReady = false
    private var pendingMarkdown: String?
    private var pendingCompletion: ((Error?) -> Void)?

    // MARK: - View

    override func loadView() {
        webView = WKWebView(frame: .zero)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
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
        webView.evaluateJavaScript("window.setTheme && window.setTheme('\(theme)')", completionHandler: nil)
    }

    private func render(_ markdown: String, completion: @escaping (Error?) -> Void) {
        let payload = encodeForJS(markdown)
        webView.evaluateJavaScript("window.renderMarkdown(\(payload))") { _, _ in completion(nil) }
    }

    private func encodeForJS(_ str: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: str, options: [.fragmentsAllowed]),
              let result = String(data: data, encoding: .utf8)
        else { return "\"\"" }
        return result
    }
}
