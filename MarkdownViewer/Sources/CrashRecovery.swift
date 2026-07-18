import Foundation

#if os(macOS)
import AppKit

/// Relaunches the app and reopens its documents after an abnormal exit.
///
/// Companion to the CoreAnimation `_lph` crash workarounds (WebView.swift,
/// `WindowColorSpacePinner`): QuartzCore can still `abort()` the process from
/// its own render queue with no app code on the faulting thread, so the last
/// line of defense is resilience — a detached watchdog relaunches the app when
/// the session ends without a clean quit, and the relaunched app reopens the
/// documents recorded in the session marker. For a read-only viewer nothing
/// else can be lost.
///
/// The marker file lives in Application Support: line 1 is the launch epoch,
/// line 2 the count of consecutive crashed relaunches, following lines are the
/// open documents' paths (refreshed as windows come and go). A clean quit
/// deletes it, so the watchdog exits silently.
///
/// Loop guard: the watchdog refuses to relaunch once the dying session's count
/// reaches `maxConsecutiveRelaunches`; the app resets the count to zero after
/// surviving `healthySessionSeconds`. An uptime-based guard does not work here:
/// the crashed process lingers as a zombie while ReportCrash writes the `.ips`
/// (observed ~10 s), which inflates the uptime the watchdog can measure.
/// Known trade-off: a force quit (SIGKILL) is indistinguishable from a crash
/// and triggers one relaunch.
@MainActor
final class CrashRecovery {
    private static let maxConsecutiveRelaunches = 3
    private static let healthySessionSeconds: TimeInterval = 60

    private let markerURL: URL
    private let launchEpoch = Int(Date().timeIntervalSince1970)
    private var relaunchCount: Int
    private var tokens: [NSObjectProtocol] = []

    init() {
        markerURL = Self.makeMarkerURL()
        let previous = Self.readMarker(at: markerURL)
        // A marker on disk means the previous session ended without a clean
        // quit — this launch is (or follows) a crash recovery.
        relaunchCount = previous.map { $0.relaunchCount + 1 } ?? 0
        if previous != nil {
            // The OS saved state was written as the process died; restoring it
            // while we reopen the same documents was observed to abort in a
            // CoreUI recursive lock during the first symbol render (macOS 27
            // beta). After a crash our own marker is the source of truth, so
            // drop the OS state entirely; a clean quit never reaches this.
            Self.removeSavedApplicationState()
        }
        // Inherit the crashed session's documents right away: if this session
        // crashes again before its windows appear, the list must survive the
        // chain so the next relaunch can still restore them.
        writeMarker(documents: previous?.documents ?? [])
        spawnWatchdog()
        observeSessionEvents()
        scheduleHealthyReset()
        if let documents = previous?.documents, !documents.isEmpty {
            reopen(documents)
        }
    }

    deinit {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: - Session marker

    private static func removeSavedApplicationState() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        guard let savedState = library.first?
            .appendingPathComponent("Saved Application State", isDirectory: true)
            .appendingPathComponent("\(bundleID).savedState", isDirectory: true) else { return }
        try? FileManager.default.removeItem(at: savedState)
    }

    private static func makeMarkerURL() -> URL {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = support.appendingPathComponent("MarkdownViewer", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("session.marker")
    }

    /// State recorded by the previous session; non-nil only after an abnormal
    /// exit (a clean quit removes the marker).
    private static func readMarker(at url: URL) -> (relaunchCount: Int, documents: [URL])? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let lines = contents.split(separator: "\n")
        let count = lines.count > 1 ? Int(lines[1]) ?? 0 : 0
        let documents = lines.dropFirst(2)
            .map { URL(fileURLWithPath: String($0)) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        return (count, documents)
    }

    private func writeMarker(documents: [URL]) {
        let body = ([String(launchEpoch), String(relaunchCount)] + documents.map(\.path))
            .joined(separator: "\n")
        try? body.write(to: markerURL, atomically: true, encoding: .utf8)
    }

    /// After surviving long enough, the session is considered healthy and the
    /// consecutive-relaunch budget is restored.
    private func scheduleHealthyReset() {
        guard relaunchCount > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.healthySessionSeconds) { [weak self] in
            self?.relaunchCount = 0
            self?.refreshMarker()
        }
    }

    private func refreshMarker(excluding closing: NSWindow? = nil) {
        var seen = Set<URL>()
        let documents = NSApp.windows
            .filter { $0 !== closing }
            .compactMap(\.representedURL)
            .filter { seen.insert($0).inserted }
        writeMarker(documents: documents)
    }

    private func observeSessionEvents() {
        let center = NotificationCenter.default
        tokens.append(center.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshMarker() }
        })
        tokens.append(center.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { [weak self] note in
            let closing = note.object as? NSWindow
            Task { @MainActor in self?.refreshMarker(excluding: closing) }
        })
        // Must run synchronously — the process exits right after this
        // notification, a Task hop would never execute.
        let marker = markerURL
        tokens.append(center.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { _ in
            try? FileManager.default.removeItem(at: marker)
        })
    }

    // MARK: - Watchdog

    /// Detached `/bin/sh` that outlives the app process. It waits for our PID
    /// to die, then relaunches this exact bundle unless the marker is gone
    /// (clean quit) or the relaunch budget is exhausted (crash-loop guard).
    private func spawnWatchdog() {
        // The sleep before relaunching matters: an instance opened while the
        // system is still processing the previous crash (ReportCrash & co.)
        // was observed to hit a CoreUI recursive-lock abort during its first
        // symbol render (macOS 27 beta). Letting the dust settle avoids it.
        let script = """
        while /bin/kill -0 "$1" 2>/dev/null; do /bin/sleep 1; done
        [ -f "$2" ] || exit 0
        count=$(/usr/bin/sed -n 2p "$2" 2>/dev/null)
        case "$count" in ''|*[!0-9]*) exit 0;; esac
        [ "$count" -lt "$4" ] || exit 0
        /bin/sleep 5
        [ -f "$2" ] || exit 0
        exec /usr/bin/open "$3"
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c", script, "markdownviewer-crash-watchdog",
            String(ProcessInfo.processInfo.processIdentifier),
            markerURL.path,
            Bundle.main.bundleURL.path,
            String(Self.maxConsecutiveRelaunches),
        ]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }

    // MARK: - Recovery

    private func reopen(_ documents: [URL]) {
        // Let the DocumentGroup scene finish launching before the open events
        // arrive, and skip anything macOS state restoration already reopened.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let alreadyOpen = Set(NSApp.windows.compactMap(\.representedURL))
            let missing = documents.filter { !alreadyOpen.contains($0) }
            guard !missing.isEmpty else { return }
            NSWorkspace.shared.open(
                missing,
                withApplicationAt: Bundle.main.bundleURL,
                configuration: NSWorkspace.OpenConfiguration(),
                completionHandler: nil
            )
        }
    }
}
#endif
