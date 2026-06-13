// Core/Tests/ClipKeepCoreTests/SmokeTests.swift
import XCTest
@testable import ClipKeepCore

final class SmokeTests: XCTestCase {
    func test_version_isSet() {
        XCTAssertEqual(ClipKeepCore.version, "0.1.0")
    }
}
