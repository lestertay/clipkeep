// App/Sources/Capture/AccessibilityPrimer.swift
import AppKit
import ApplicationServices

/// Proactively asks Chromium/Electron apps to build their accessibility tree as soon as
/// they become active, so the text caret is exposed the *first* time the popup opens.
///
/// Why: Chromium builds its accessibility tree lazily and asynchronously after being asked.
/// If we only enable it at popup time, the very first lookup races the tree build and misses.
/// Priming on app-activation gives the tree time to materialize before you hit the hotkey.
///
/// We set only `AXManualAccessibility` here — it's the Electron-specific opt-in and a no-op
/// for non-Chromium apps, so priming every activated app is safe. (The broader, more
/// side-effecting `AXEnhancedUserInterface` is set narrowly, only on the app you actually
/// open the popup over — see `CaretLocator`.)
final class AccessibilityPrimer {
    func start() {
        Self.prime(NSWorkspace.shared.frontmostApplication)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            Self.prime(app)
        }
    }

    private static func prime(_ app: NSRunningApplication?) {
        guard AXIsProcessTrusted(), let pid = app?.processIdentifier else { return }
        let element = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(element, "AXManualAccessibility" as CFString, kCFBooleanTrue)
    }
}
