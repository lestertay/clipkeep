// Core/Sources/ClipKeepCore/Capture/ClipboardMonitor.swift
import Foundation

/// Pure change-detection. The timer that calls `poll()` lives in the app layer
/// (see App/Sources/Capture/MonitorRunner.swift) so this stays unit-testable.
public final class ClipboardMonitor {
    private let reader: PasteboardReading
    private let onChange: () -> Void
    public private(set) var lastChangeCount: Int

    public init(reader: PasteboardReading, onChange: @escaping () -> Void) {
        self.reader = reader
        self.onChange = onChange
        self.lastChangeCount = reader.changeCount   // baseline; ignore pre-existing content
    }

    public func poll() {
        let current = reader.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current
        onChange()
    }
}
