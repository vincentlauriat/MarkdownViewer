#if os(macOS)
import AppKit
import Foundation
import os.log

enum UpdateChecker {
    private static let logger = Logger(subsystem: "com.vincent.MarkdownViewer", category: "update")
    private static let releasesAPI = URL(string: "https://api.github.com/repos/vincentlauriat/MarkdownViewer/releases/latest")!
    private static let lastCheckKey = "MarkdownViewer.lastUpdateCheck"
    private static let skippedVersionKey = "MarkdownViewer.skippedUpdateVersion"
    private static let autoCheckInterval: TimeInterval = 7 * 24 * 3600

    struct Release: Decodable {
        let tagName: String
        let name: String
        let body: String
        let htmlURL: URL
        let assets: [Asset]

        struct Asset: Decodable {
            let name: String
            let browserDownloadURL: URL

            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadURL = "browser_download_url"
            }
        }

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name, body, assets
            case htmlURL = "html_url"
        }
    }

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Called from `MarkdownViewerApp` on launch. Throttled to once a week.
    static func checkOnLaunchIfNeeded() {
        let last = UserDefaults.standard.double(forKey: lastCheckKey)
        let now = Date().timeIntervalSince1970
        guard now - last > autoCheckInterval else {
            logger.debug("Update check skipped (last check was \(Int(now - last))s ago)")
            return
        }
        Task { await check(silent: true) }
    }

    /// Triggered from the `Check for Updates…` menu item. Shows feedback even when up-to-date.
    static func checkFromMenu() {
        Task { await check(silent: false) }
    }

    private static func check(silent: Bool) async {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)
        do {
            var request = URLRequest(url: releasesAPI)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("MarkdownViewer/\(currentVersion)", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw UpdateError.invalidResponse
            }
            // 404 = no published release yet — silent in auto mode, friendly message in menu mode
            if http.statusCode == 404 {
                logger.info("No published release yet (HTTP 404)")
                if !silent { await MainActor.run { showUpToDate() } }
                return
            }
            guard http.statusCode == 200 else {
                throw UpdateError.httpStatus(http.statusCode)
            }

            let release = try JSONDecoder().decode(Release.self, from: data)
            let latest = stripVPrefix(release.tagName)
            let current = currentVersion
            logger.info("Latest release on GitHub: \(latest, privacy: .public), current bundle: \(current, privacy: .public)")

            switch compareSemver(latest, current) {
            case .orderedDescending:
                let skipped = UserDefaults.standard.string(forKey: skippedVersionKey)
                if silent && skipped == latest {
                    logger.debug("User has skipped \(latest, privacy: .public), staying quiet")
                    return
                }
                await MainActor.run { promptUpdate(release: release, latest: latest, silent: silent) }
            case .orderedSame, .orderedAscending:
                if !silent { await MainActor.run { showUpToDate() } }
            }
        } catch {
            logger.error("Update check failed: \(error.localizedDescription, privacy: .public)")
            if !silent {
                await MainActor.run { showError(error.localizedDescription) }
            }
        }
    }

    private static func stripVPrefix(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    /// Numeric semver comparison: "1.10.0" > "1.9.0".
    /// Pre-release suffixes (e.g. "-beta") are ignored — adjust if we adopt them.
    private static func compareSemver(_ a: String, _ b: String) -> ComparisonResult {
        let parse: (String) -> [Int] = { raw in
            let core = raw.split(separator: "-", maxSplits: 1).first.map(String.init) ?? raw
            return core.split(separator: ".").map { Int($0) ?? 0 }
        }
        let aP = parse(a)
        let bP = parse(b)
        for i in 0..<max(aP.count, bP.count) {
            let ai = i < aP.count ? aP[i] : 0
            let bi = i < bP.count ? bP[i] : 0
            if ai > bi { return .orderedDescending }
            if ai < bi { return .orderedAscending }
        }
        return .orderedSame
    }

    @MainActor
    private static func promptUpdate(release: Release, latest: String, silent: Bool) {
        let alert = NSAlert()
        alert.messageText = "MarkdownViewer \(latest) is available"
        let notes = release.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let truncated = notes.count > 600 ? String(notes.prefix(600)) + "…" : notes
        alert.informativeText = "You're running \(currentVersion).\n\nRelease notes:\n\(truncated.isEmpty ? "(no notes provided)" : truncated)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        if silent {
            alert.addButton(withTitle: "Skip This Version")
        }

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            let dmg = release.assets.first { $0.name.hasSuffix(".dmg") }?.browserDownloadURL
            NSWorkspace.shared.open(dmg ?? release.htmlURL)
        case .alertThirdButtonReturn:
            UserDefaults.standard.set(latest, forKey: skippedVersionKey)
            logger.info("User skipped version \(latest, privacy: .public)")
        default:
            break
        }
    }

    @MainActor
    private static func showUpToDate() {
        let alert = NSAlert()
        alert.messageText = "You're up to date"
        alert.informativeText = "MarkdownViewer \(currentVersion) is the latest version available."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @MainActor
    private static func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Couldn't check for updates"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private enum UpdateError: LocalizedError {
        case invalidResponse
        case httpStatus(Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Invalid response from GitHub."
            case .httpStatus(let code): return "GitHub returned HTTP \(code)."
            }
        }
    }
}
#endif
