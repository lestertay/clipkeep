// App/Sources/AppEnvironment.swift
import AppKit
import SwiftUI
import ClipKeepCore

/// Owns and wires the long-lived objects.
///
/// Concurrency: `ClipboardMonitor.poll()` runs on `MonitorRunner`'s background queue,
/// and its `onChange` fires there too. Because `onChange` only fires on a *real*
/// clipboard change (rare, and cheap relative to polling), we hop the actual capture
/// work onto the main actor. That lets us read the frontmost app and `Preferences`
/// (both main-actor-bound) naturally, and the capture itself touches GRDB / disk
/// which are fast. The captured `coordinator`, `store`, and `imageStore` are
/// `Sendable` (see their `@unchecked Sendable` conformances in Core).
@MainActor
final class AppEnvironment {
    let preferences = Preferences()
    let paths: AppPaths
    let store: HistoryStore
    let imageStore: ImageStore
    let coordinator: CaptureCoordinator
    let monitorRunner: MonitorRunner
    let pasteService: PasteService
    let popupController: PopupController
    private var hotkeyManager: HotkeyManager?

    init() {
        let paths = AppPaths.standard()
        try! paths.ensureDirectories()
        self.paths = paths
        self.store = try! HistoryStore(path: paths.databaseURL.path)
        self.imageStore = ImageStore(paths: paths)

        let prefs = preferences
        let config = CaptureConfig(maxImageBytes: prefs.maxSingleImageBytes,
                                   thumbnailMaxPixel: 96,
                                   excludedBundleIDs: Set(prefs.excludedBundleIDs))
        let coordinator = CaptureCoordinator(store: store, imageStore: imageStore,
                                             filter: PrivacyFilter(), extractor: ClipExtractor(),
                                             config: config)
        self.coordinator = coordinator

        // Sendable values/objects to hand into the background closure.
        let store = self.store
        let imageStore = self.imageStore

        let reader = NSPasteboardReader()
        let monitor = ClipboardMonitor(reader: reader) {
            // Fires on the monitor's background queue, only on a real clipboard change.
            // Hop to the main actor to read the frontmost app + prefs and perform capture.
            Task { @MainActor in
                let sourceID = FrontmostApp.bundleID()
                let captureReader = NSPasteboardReader()
                try? coordinator.capture(reader: captureReader, sourceBundleID: sourceID, now: Date())
                // Periodic retention sweep is cheap; run after each capture.
                _ = try? coordinator.runRetentionSweep(store: store, imageStore: imageStore,
                                                       maxCount: prefs.maxCount, maxAge: prefs.maxAge,
                                                       maxImageBytes: prefs.maxImageBytes)
            }
        }
        self.monitorRunner = MonitorRunner(monitor: monitor)

        self.pasteService = PasteService(paths: paths)
        self.popupController = PopupController(store: self.store, pasteService: pasteService, thumbsDir: paths.thumbsDir)
    }

    func start() {
        monitorRunner.setPaused(preferences.paused)
        monitorRunner.start()
        hotkeyManager = HotkeyManager { [weak self] in self?.popupController.toggle() }
    }

    func clearHistory() {
        let removed = (try? store.clearAll()) ?? []
        imageStore.deleteFiles(removed)
    }

    func presentSettings(reusing window: inout NSWindow?) {
        if let window { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let view = SettingsView(preferences: preferences, onClearHistory: { [weak self] in self?.clearHistory() })
        let hosting = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: hosting)
        win.title = "ClipKeep Settings"
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }
}
