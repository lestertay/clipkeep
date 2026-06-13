import XCTest
@testable import ClipKeepCore

final class ClipListStateTests: XCTestCase {
    func test_moveDownAndUp_clampToBounds() {
        var s = ClipListState(count: 3)
        XCTAssertEqual(s.selectedIndex, 0)
        s.moveDown(); XCTAssertEqual(s.selectedIndex, 1)
        s.moveDown(); s.moveDown(); XCTAssertEqual(s.selectedIndex, 2, "clamps at last")
        s.moveUp(); XCTAssertEqual(s.selectedIndex, 1)
        s.moveUp(); s.moveUp(); XCTAssertEqual(s.selectedIndex, 0, "clamps at first")
    }

    func test_updateCount_clampsSelection() {
        var s = ClipListState(count: 5)
        s.moveDown(); s.moveDown(); s.moveDown()      // index 3
        s.updateCount(2)
        XCTAssertEqual(s.selectedIndex, 1)
    }

    func test_quickSelectIndex_mapsOneThroughNine() {
        let s = ClipListState(count: 12)
        XCTAssertEqual(s.indexForQuickKey(1), 0)
        XCTAssertEqual(s.indexForQuickKey(9), 8)
        XCTAssertNil(s.indexForQuickKey(0))
        XCTAssertNil(s.indexForQuickKey(10))
    }

    func test_quickSelectIndex_nilWhenOutOfRange() {
        let s = ClipListState(count: 3)
        XCTAssertNil(s.indexForQuickKey(5), "only 3 items -> key 5 invalid")
    }

    func test_emptyList_selectionStaysAtZero() {
        var s = ClipListState(count: 0)
        s.moveDown(); XCTAssertEqual(s.selectedIndex, 0)
    }
}
