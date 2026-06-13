// App/Sources/Capture/NSPasteboardReader.swift
import AppKit
import ClipKeepCore

struct NSPasteboardReader: PasteboardReading {
    let pasteboard: NSPasteboard
    init(_ pasteboard: NSPasteboard = .general) { self.pasteboard = pasteboard }

    var changeCount: Int { pasteboard.changeCount }
    func types() -> [String] { (pasteboard.types ?? []).map(\.rawValue) }
    func string(forType type: String) -> String? { pasteboard.string(forType: .init(type)) }
    func data(forType type: String) -> Data? { pasteboard.data(forType: .init(type)) }
}
