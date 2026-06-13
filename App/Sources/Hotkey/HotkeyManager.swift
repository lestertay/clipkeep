// App/Sources/Hotkey/HotkeyManager.swift
import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showPopup = Self("showPopup", default: .init(.v, modifiers: [.command, .shift]))
}

@MainActor
final class HotkeyManager {
    private let onTrigger: () -> Void
    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        KeyboardShortcuts.onKeyDown(for: .showPopup) { [onTrigger] in onTrigger() }
    }
}
