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
        center(panel)
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

    private func center(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(x: f.midX - size.width / 2, y: f.midY - size.height / 2 + 80)
        panel.setFrameOrigin(origin)
    }
}
