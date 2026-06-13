// Core/Tests/ClipKeepCoreTests/ImageCapTests.swift
import XCTest
@testable import ClipKeepCore

final class ImageCapTests: XCTestCase {
    private func imageClip(_ name: String, bytes: Int, at t: TimeInterval) -> Clip {
        Clip(kind: .image, preview: name, imageFile: "\(name).png", thumbFile: "\(name).jpg",
             width: 10, height: 10, byteSize: bytes, contentHash: name,
             createdAt: Date(timeIntervalSince1970: t), lastUsedAt: Date(timeIntervalSince1970: t))
    }

    func test_pruneImages_dropsOldestUntilUnderCap() throws {
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(imageClip("old", bytes: 600, at: 100))
        _ = try store.record(imageClip("mid", bytes: 600, at: 200))
        _ = try store.record(imageClip("new", bytes: 600, at: 300))
        // total 1800; cap 1000 -> must drop oldest ("old"), leaving 1200... drop "mid" too -> 600.
        let removed = try store.pruneImages(maxTotalBytes: 1000)
        XCTAssertEqual(Set(removed), ["old.png", "old.jpg", "mid.png", "mid.jpg"])
        XCTAssertEqual(try store.recent(limit: 10).compactMap(\.imageFile), ["new.png"])
    }

    func test_pruneImages_ignoresTextClips() throws {
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(Clip(kind: .text, text: "t", preview: "t", contentHash: "t",
                                  createdAt: Date(timeIntervalSince1970: 1),
                                  lastUsedAt: Date(timeIntervalSince1970: 1)))
        XCTAssertEqual(try store.pruneImages(maxTotalBytes: 0).count, 0)
    }
}
