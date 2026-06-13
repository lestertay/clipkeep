// Core/Tests/ClipKeepCoreTests/HistoryStoreTests.swift
import XCTest
@testable import ClipKeepCore

final class HistoryStoreTests: XCTestCase {
    private func makeStore() throws -> HistoryStore { try HistoryStore(inMemory: true) }

    private func textClip(_ s: String, at t: TimeInterval) -> Clip {
        Clip(kind: .text, text: s, preview: s,
             contentHash: Hashing.sha256(text: s),
             createdAt: Date(timeIntervalSince1970: t),
             lastUsedAt: Date(timeIntervalSince1970: t))
    }

    func test_record_assignsId_andRoundTrips() throws {
        let store = try makeStore()
        let saved = try store.record(textClip("hello", at: 100))
        XCTAssertNotNil(saved.id)
        let recent = try store.recent(limit: 10)
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.text, "hello")
    }

    func test_recent_isOrderedByLastUsedDescending() throws {
        let store = try makeStore()
        _ = try store.record(textClip("old", at: 100))
        _ = try store.record(textClip("new", at: 200))
        let recent = try store.recent(limit: 10)
        XCTAssertEqual(recent.map(\.text), ["new", "old"])
    }
}
