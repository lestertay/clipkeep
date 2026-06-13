// App/Sources/Paste/PasteService.swift
import AppKit
import ClipKeepCore

@MainActor
final class PasteService {
    private let paths: AppPaths
    init(paths: AppPaths) { self.paths = paths }

    /// Write the clip to the pasteboard; if autoPaste and Accessibility is granted,
    /// reactivate the target app and send ⌘V.
    func paste(_ clip: Clip, into targetApp: NSRunningApplication?, autoPaste: Bool) {
        writeToPasteboard(clip)
        guard autoPaste else { return }
        guard AccessibilityAuthorizer.isTrusted else {
            AccessibilityAuthorizer.promptIfNeeded()
            return   // content is on the clipboard; user can paste manually
        }
        targetApp?.activate()
        // Give the target a beat to come forward before synthesizing the keystroke.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            Self.sendCommandV()
        }
    }

    private func writeToPasteboard(_ clip: Clip) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch clip.kind {
        case .text:
            if let text = clip.text { pb.setString(text, forType: .string) }
        case .image:
            if let file = clip.imageFile,
               let data = try? Data(contentsOf: paths.imagesDir.appendingPathComponent(file)) {
                pb.setData(data, forType: .png)
            }
        }
    }

    private static func sendCommandV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09   // 'v'
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
