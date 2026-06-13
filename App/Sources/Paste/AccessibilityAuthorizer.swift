// App/Sources/Paste/AccessibilityAuthorizer.swift
import AppKit
import ApplicationServices

enum AccessibilityAuthorizer {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    @discardableResult
    static func promptIfNeeded() -> Bool {
        // `kAXTrustedCheckOptionPrompt` is an imported C `var` global, which Swift 6
        // strict concurrency rejects as shared mutable state. Use its documented
        // string value ("AXTrustedCheckOptionPrompt") directly instead.
        let promptKey = "AXTrustedCheckOptionPrompt"
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSettingsPane() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
