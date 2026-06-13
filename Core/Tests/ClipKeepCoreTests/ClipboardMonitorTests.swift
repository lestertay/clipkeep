// Core/Tests/ClipKeepCoreTests/ClipboardMonitorTests.swift
import XCTest
@testable import ClipKeepCore

final class ClipboardMonitorTests: XCTestCase {
    func test_poll_firesOnlyWhenChangeCountIncreases() {
        let pb = FakePasteboard()
        var fires = 0
        let monitor = ClipboardMonitor(reader: pb) { fires += 1 }

        monitor.poll()                 // no change yet
        XCTAssertEqual(fires, 0)

        pb.setText("a")                // changeCount -> 1
        monitor.poll()
        XCTAssertEqual(fires, 1)

        monitor.poll()                 // unchanged
        XCTAssertEqual(fires, 1)

        pb.setText("b")                // changeCount -> 2
        monitor.poll()
        XCTAssertEqual(fires, 2)
    }

    func test_doesNotFireForInitialContentAlreadyOnPasteboard() {
        let pb = FakePasteboard()
        pb.setText("preexisting")      // changeCount is 1 before monitor starts
        var fires = 0
        let monitor = ClipboardMonitor(reader: pb) { fires += 1 }
        monitor.poll()
        XCTAssertEqual(fires, 0, "must baseline to current changeCount on init")
    }
}
