import XCTest
@testable import ClipKeepCore

final class HashingTests: XCTestCase {
    func test_sameTextSameHash() {
        XCTAssertEqual(Hashing.sha256(text: "hello"), Hashing.sha256(text: "hello"))
    }
    func test_differentTextDifferentHash() {
        XCTAssertNotEqual(Hashing.sha256(text: "hello"), Hashing.sha256(text: "world"))
    }
    func test_dataHashIsHex64() {
        let h = Hashing.sha256(data: Data([0x01, 0x02, 0x03]))
        XCTAssertEqual(h.count, 64)
        XCTAssertTrue(h.allSatisfy { $0.isHexDigit })
    }
}
