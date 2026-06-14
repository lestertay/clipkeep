// App/Sources/Popup/PopupController.swift
import AppKit
import SwiftUI
import ClipKeepCore

@MainActor
final class PopupController {
    private let store: HistoryStore
    private let pasteService: PasteService
    private let thumbsDir: URL
    private let preferences: Preferences
    private var panel: PopupPanel?
    private var targetApp: NSRunningApplication?
    private var optionMonitor: Any?
    private var lastTopLeft: NSPoint?

    init(store: HistoryStore, pasteService: PasteService, thumbsDir: URL, preferences: Preferences) {
        self.store = store
        self.pasteService = pasteService
        self.thumbsDir = thumbsDir
        self.preferences = preferences
    }

    func toggle() { panel?.isVisible == true ? hide() : show() }

    func show() {
        targetApp = FrontmostApp.current()   // capture BEFORE we show

        let model = PopupViewModel(store: store)
        let root = HistoryListView(
            model: model,
            thumbsDir: thumbsDir,
            onPaste: { [weak self] clip, autoPaste in
                self?.pasteService.paste(clip, into: self?.targetApp, autoPaste: autoPaste)
            },
            onClose: { [weak self] in self?.hide() }
        )

        let hosting = NSHostingView(rootView: root)
        let size = NSSize(width: 360, height: 420)
        let panel = PopupPanel(contentRect: NSRect(origin: .zero, size: size))
        panel.contentView = hosting
        positionPanel(panel)   // query caret BEFORE the panel takes key
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel

        // ⌥↵ = copy without auto-paste. Local monitor while the panel is up.
        optionMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel?.isVisible == true else { return event }
            if event.keyCode == 36, event.modifierFlags.contains(.option) {  // return + option
                if let clip = model.selectedClip {
                    self.pasteService.paste(clip, into: self.targetApp, autoPaste: false)
                    self.hide()
                }
                return nil
            }
            return event
        }
    }

    func hide() {
        if let optionMonitor { NSEvent.removeMonitor(optionMonitor) }
        optionMonitor = nil
        panel?.orderOut(nil)
        panel = nil
    }

    /// Position the panel per the user's preference (caret / mouse / center / last position).
    /// The anchor is the desired top-left of the panel in Cocoa global coords (bottom-left
    /// origin), which is then clamped to its screen's visible area. Records where it landed
    /// so the "last position" mode can reuse it.
    private func positionPanel(_ panel: NSPanel) {
        let size = panel.frame.size
        let mode = PopupPosition(rawValue: preferences.popupPosition) ?? .caret

        let anchorTopLeft: NSPoint
        switch mode {
        case .caret:
            if let anchor = CaretLocator.anchorRect() {
                anchorTopLeft = NSPoint(x: anchor.minX, y: anchor.minY - 6)   // just below the caret/field
            } else {
                anchorTopLeft = mouseAnchor()
            }
        case .mouse:
            anchorTopLeft = mouseAnchor()
        case .center:
            anchorTopLeft = centerAnchor(for: size)
        case .lastPosition:
            anchorTopLeft = lastTopLeft ?? centerAnchor(for: size)
        }

        // Panel origin is bottom-left; place its top-left at the anchor, clamped on-screen.
        var x = anchorTopLeft.x
        var y = anchorTopLeft.y - size.height
        let screen = NSScreen.screens.first { $0.frame.contains(anchorTopLeft) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(origin: .zero, size: size)
        x = min(max(x, visible.minX), visible.maxX - size.width)
        y = min(max(y, visible.minY), visible.maxY - size.height)
        panel.setFrameOrigin(NSPoint(x: x, y: y))

        lastTopLeft = NSPoint(x: x, y: y + size.height)   // remember the placed top-left
    }

    private func mouseAnchor() -> NSPoint {
        let m = NSEvent.mouseLocation
        return NSPoint(x: m.x - 16, y: m.y - 16)
    }

    private func centerAnchor(for size: NSSize) -> NSPoint {
        let vf = NSScreen.main?.visibleFrame ?? NSRect(origin: .zero, size: size)
        return NSPoint(x: vf.midX - size.width / 2, y: vf.midY + size.height / 2)
    }
}
