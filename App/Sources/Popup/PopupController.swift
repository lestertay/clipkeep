// App/Sources/Popup/PopupController.swift
import AppKit
import SwiftUI
import ClipKeepCore

@MainActor
final class PopupController {
    private let store: HistoryStore
    private let pasteService: PasteService
    private let thumbsDir: URL
    private var panel: PopupPanel?
    private var targetApp: NSRunningApplication?
    private var optionMonitor: Any?

    init(store: HistoryStore, pasteService: PasteService, thumbsDir: URL) {
        self.store = store
        self.pasteService = pasteService
        self.thumbsDir = thumbsDir
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
        positionAtCursor(panel)
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

    /// Position the panel near the mouse cursor, on the cursor's screen,
    /// clamped so the whole panel stays within that screen's visible area.
    private func positionAtCursor(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation   // global screen coords, bottom-left origin
        let size = panel.frame.size
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(origin: .zero, size: size)

        // Cursor sits just inside the panel's top-left; panel extends down-right.
        var x = mouse.x - 16
        var y = mouse.y - size.height + 16

        x = min(max(x, visible.minX), visible.maxX - size.width)
        y = min(max(y, visible.minY), visible.maxY - size.height)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
