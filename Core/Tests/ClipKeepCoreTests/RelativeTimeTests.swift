import XCTest
@testable import ClipKeepCore

final class RelativeTimeTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    func test_underAMinute_isNow() {
        XCTAssertEqual(RelativeTime.string(for: now.addingTimeInterval(-5), now: now), "now")
    }
    func test_minutes() {
        XCTAssertEqual(RelativeTime.string(for: now.addingTimeInterval(-120), now: now), "2m")
    }
    func test_hours() {
        XCTAssertEqual(RelativeTime.string(for: now.addingTimeInterval(-7200), now: now), "2h")
    }
    func test_days() {
        XCTAssertEqual(RelativeTime.string(for: now.addingTimeInterval(-172800), now: now), "2d")
    }
}
