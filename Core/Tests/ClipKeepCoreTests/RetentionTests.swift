// Core/Tests/ClipKeepCoreTests/RetentionTests.swift
import XCTest
@testable import ClipKeepCore

final class RetentionTests: XCTestCase {
    private func textClip(_ s: String, at t: TimeInterval) -> Clip {
        Clip(kind: .text, text: s, preview: s,
             contentHash: Hashing.sha256(text: s),
             createdAt: Date(timeIntervalSince1970: t),
             lastUsedAt: Date(timeIntervalSince1970: t))
    }

    func test_prune_byMaxCount_keepsNewest() throws {
        let store = try HistoryStore(inMemory: true)
        for i in 1...5 { _ = try store.record(textClip("c\(i)", at: TimeInterval(i))) }
        let removed = try store.prune(maxCount: 3, maxAge: .infinity, now: Date(timeIntervalSince1970: 100))
        XCTAssertTrue(removed.isEmpty, "text clips have no image files")
        XCTAssertEqual(try store.recent(limit: 10).map(\.text), ["c5", "c4", "c3"])
    }

    func test_prune_byMaxAge_removesOldOnes() throws {
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(textClip("old", at: 0))      // very old
        _ = try store.record(textClip("fresh", at: 1000))
        let now = Date(timeIntervalSince1970: 1000)
        _ = try store.prune(maxCount: 1000, maxAge: 100, now: now)  // keep < 100s old
        XCTAssertEqual(try store.recent(limit: 10).map(\.text), ["fresh"])
    }

    func test_prune_returnsImageFilesForRemovedImageClips() throws {
        let store = try HistoryStore(inMemory: true)
        let img = Clip(kind: .image, preview: "x.png", imageFile: "x.png", thumbFile: "x.jpg",
                       width: 1, height: 1, byteSize: 1, contentHash: "h",
                       createdAt: Date(timeIntervalSince1970: 1), lastUsedAt: Date(timeIntervalSince1970: 1))
        _ = try store.record(img)
        _ = try store.record(textClip("keep", at: 1000))
        let removed = try store.prune(maxCount: 1, maxAge: .infinity, now: Date(timeIntervalSince1970: 1000))
        XCTAssertEqual(Set(removed), ["x.png", "x.jpg"])
    }
}
