// Core/Tests/ClipKeepCoreTests/DeduplicationTests.swift
import XCTest
@testable import ClipKeepCore

final class DeduplicationTests: XCTestCase {
    private func textClip(_ s: String, at t: TimeInterval) -> Clip {
        Clip(kind: .text, text: s, preview: s,
             contentHash: Hashing.sha256(text: s),
             createdAt: Date(timeIntervalSince1970: t),
             lastUsedAt: Date(timeIntervalSince1970: t))
    }

    func test_recordingSameContentTwice_doesNotDuplicate_andMovesToTop() throws {
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(textClip("dup", at: 100))
        _ = try store.record(textClip("other", at: 150))
        _ = try store.record(textClip("dup", at: 200))   // same hash as first

        let recent = try store.recent(limit: 10)
        XCTAssertEqual(recent.count, 2, "duplicate must not create a new row")
        XCTAssertEqual(recent.first?.text, "dup", "re-copied item moves to top")
        XCTAssertEqual(recent.first?.lastUsedAt, Date(timeIntervalSince1970: 200))
    }

    func test_nonAdjacentDuplicate_stillInsertsBecauseOnlyMostRecentChecked() throws {
        // Spec: de-dupe only against the most-recent clip.
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(textClip("a", at: 100))
        _ = try store.record(textClip("b", at: 150))
        _ = try store.record(textClip("a", at: 200))    // "a" is not the most recent ("b" is)
        XCTAssertEqual(try store.recent(limit: 10).count, 3)
    }
}
