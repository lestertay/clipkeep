// Core/Tests/ClipKeepCoreTests/FakePasteboardTests.swift
import XCTest
@testable import ClipKeepCore

final class FakePasteboardTests: XCTestCase {
    func test_setText_incrementsChangeCount_andExposesValue() {
        let pb = FakePasteboard()
        XCTAssertEqual(pb.changeCount, 0)
        pb.setText("hi")
        XCTAssertEqual(pb.changeCount, 1)
        XCTAssertEqual(pb.types(), [PasteboardType.utf8PlainText])
        XCTAssertEqual(pb.string(forType: PasteboardType.utf8PlainText), "hi")
    }
}
