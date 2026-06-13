import Foundation

public struct ClipListState: Equatable {
    public private(set) var count: Int
    public private(set) var selectedIndex: Int

    public init(count: Int) {
        self.count = count
        self.selectedIndex = 0
    }

    public mutating func moveDown() { selectedIndex = min(selectedIndex + 1, max(0, count - 1)) }
    public mutating func moveUp() { selectedIndex = max(selectedIndex - 1, 0) }

    public mutating func updateCount(_ newCount: Int) {
        count = newCount
        selectedIndex = min(selectedIndex, max(0, newCount - 1))
    }

    /// Maps number keys 1...9 to list indices 0...8, if within range.
    public func indexForQuickKey(_ key: Int) -> Int? {
        guard (1...9).contains(key) else { return nil }
        let index = key - 1
        return index < count ? index : nil
    }
}
