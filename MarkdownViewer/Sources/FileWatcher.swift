import Foundation
import os

private let log = Logger(subsystem: "com.vincent.MarkdownViewer", category: "FileWatcher")

@MainActor
final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var debounceTask: Task<Void, Never>?
    private(set) var url: URL
    private let onChange: () -> Void

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        start()
    }

    deinit {
        source?.cancel()
        if fileDescriptor >= 0 { close(fileDescriptor) }
    }

    func stop() {
        debounceTask?.cancel()
        debounceTask = nil
        source?.cancel()
        source = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func start() {
        stop()
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            log.error("failed to open \(self.url.path, privacy: .public)")
            return
        }
        fileDescriptor = fd
        log.info("armed on \(self.url.lastPathComponent, privacy: .public) fd=\(fd)")

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let event = source.data
            self.handle(event: event)
        }
        source.setCancelHandler {
            close(fd)
        }
        self.source = source
        source.resume()
    }

    private func handle(event: DispatchSource.FileSystemEvent) {
        // Atomic save (vim, VS Code, etc.) supprime / renomme le fichier d'origine.
        // On doit re-souscrire à un nouveau file descriptor sur le même path.
        let needsRebind = event.contains(.delete) || event.contains(.rename)

        log.info("event raw=\(event.rawValue) needsRebind=\(needsRebind)")
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000) // 120 ms
            guard !Task.isCancelled, let self else { return }
            if needsRebind {
                self.start()
            }
            log.info("triggering onChange for \(self.url.lastPathComponent, privacy: .public)")
            self.onChange()
        }
    }
}
