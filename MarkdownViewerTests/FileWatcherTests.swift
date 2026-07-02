import XCTest
@testable import MarkdownViewer

@MainActor
final class FileWatcherTests: XCTestCase {

    private var tempDir: URL!
    private var fileURL: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileWatcherTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        fileURL = tempDir.appendingPathComponent("doc.md")
        try "initial".write(to: fileURL, atomically: true, encoding: .utf8)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testInPlaceWriteTriggersOnChange() async throws {
        let changed = expectation(description: "onChange after in-place write")
        changed.assertForOverFulfill = false
        let watcher = FileWatcher(url: fileURL) { changed.fulfill() }

        // Non-atomic append so the event fires on the same file descriptor
        let handle = try FileHandle(forWritingTo: fileURL)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(" — edited".utf8))
        try handle.close()

        await fulfillment(of: [changed], timeout: 5)
        watcher.stop()
    }

    func testAtomicSaveTriggersOnChangeAndRebinds() async throws {
        let changed = expectation(description: "onChange after atomic save")
        changed.assertForOverFulfill = false
        let watcher = FileWatcher(url: fileURL) { changed.fulfill() }

        // atomically: true writes a temp file then renames it over the path —
        // the vim / VS Code save behaviour the watcher must survive.
        try "atomic content".write(to: fileURL, atomically: true, encoding: .utf8)

        await fulfillment(of: [changed], timeout: 5)

        // The watcher must have re-armed on the new inode: a second edit fires again.
        let changedAgain = expectation(description: "onChange after post-rebind write")
        changedAgain.assertForOverFulfill = false
        let rearmed = FileWatcher(url: fileURL) { changedAgain.fulfill() }
        try "atomic content 2".write(to: fileURL, atomically: true, encoding: .utf8)
        await fulfillment(of: [changedAgain], timeout: 5)

        watcher.stop()
        rearmed.stop()
    }

    func testStopPreventsFurtherCallbacks() async throws {
        var callbackCount = 0
        let watcher = FileWatcher(url: fileURL) { callbackCount += 1 }
        watcher.stop()

        try "post-stop".write(to: fileURL, atomically: false, encoding: .utf8)
        try await Task.sleep(nanoseconds: 500_000_000) // > debounce (120 ms)

        XCTAssertEqual(callbackCount, 0)
    }
}
