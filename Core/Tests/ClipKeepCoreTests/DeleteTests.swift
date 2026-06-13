// Core/Tests/ClipKeepCoreTests/DeleteTests.swift
import XCTest
@testable import ClipKeepCore

final class DeleteTests: XCTestCase {
    private func textClip(_ s: String, at t: TimeInterval) -> Clip {
        Clip(kind: .text, text: s, preview: s,
             contentHash: Hashing.sha256(text: s),
             createdAt: Date(timeIntervalSince1970: t),
             lastUsedAt: Date(timeIntervalSince1970: t))
    }
    private func imageClip(file: String, thumb: String, at t: TimeInterval) -> Clip {
        Clip(kind: .image, preview: file, imageFile: file, thumbFile: thumb,
             width: 10, height: 10, byteSize: 100,
             contentHash: Hashing.sha256(text: file),
             createdAt: Date(timeIntervalSince1970: t),
             lastUsedAt: Date(timeIntervalSince1970: t))
    }

    func test_delete_removesRow_andReturnsImageFiles() throws {
        let store = try HistoryStore(inMemory: true)
        let saved = try store.record(imageClip(file: "a.png", thumb: "a.jpg", at: 100))
        let files = try store.delete(id: saved.id!)
        XCTAssertEqual(Set(files), ["a.png", "a.jpg"])
        XCTAssertEqual(try store.recent(limit: 10).count, 0)
    }

    func test_clearAll_returnsAllImageFiles() throws {
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(textClip("plain", at: 100))
        _ = try store.record(imageClip(file: "b.png", thumb: "b.jpg", at: 110))
        let files = try store.clearAll()
        XCTAssertEqual(Set(files), ["b.png", "b.jpg"])
        XCTAssertEqual(try store.recent(limit: 10).count, 0)
    }
}
