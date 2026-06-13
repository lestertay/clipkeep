// Core/Tests/ClipKeepCoreTests/SearchTests.swift
import XCTest
@testable import ClipKeepCore

final class SearchTests: XCTestCase {
    private func textClip(_ s: String, at t: TimeInterval) -> Clip {
        Clip(kind: .text, text: s, preview: s,
             contentHash: Hashing.sha256(text: s),
             createdAt: Date(timeIntervalSince1970: t),
             lastUsedAt: Date(timeIntervalSince1970: t))
    }

    func test_search_matchesByPrefix() throws {
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(textClip("github.com/groue/GRDB", at: 100))
        _ = try store.record(textClip("totally unrelated", at: 110))
        _ = try store.record(textClip("git rebase -i", at: 120))

        let hits = try store.search("git", limit: 10)
        XCTAssertEqual(Set(hits.compactMap(\.text)), ["github.com/groue/GRDB", "git rebase -i"])
    }

    func test_search_emptyQuery_returnsRecent() throws {
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(textClip("a", at: 100))
        _ = try store.record(textClip("b", at: 200))
        XCTAssertEqual(try store.search("", limit: 10).map(\.text), ["b", "a"])
    }

    func test_search_isCaseInsensitive() throws {
        let store = try HistoryStore(inMemory: true)
        _ = try store.record(textClip("Hello World", at: 100))
        XCTAssertEqual(try store.search("hello", limit: 10).count, 1)
    }
}
