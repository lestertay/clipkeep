// App/Sources/AppDelegate.swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var environment: AppEnvironment?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let env = AppEnvironment()
        environment = env

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipKeep")

        let menu = NSMenu()
        menu.addItem(withTitle: "Open History", action: #selector(openHistory), keyEquivalent: "")
        menu.addItem(.separator())
        let pause = NSMenuItem(title: "Pause Capturing", action: #selector(togglePause), keyEquivalent: "")
        pause.state = env.preferences.paused ? .on : .off
        menu.addItem(pause)
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit ClipKeep", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        for menuItem in menu.items where menuItem.action != nil && menuItem.action != #selector(NSApplication.terminate(_:)) {
            menuItem.target = self
        }
        item.menu = menu
        statusItem = item

        env.start()
    }

    @objc private func openHistory() { environment?.popupController.show() }

    @objc private func togglePause(_ sender: NSMenuItem) {
        guard let env = environment else { return }
        env.preferences.paused.toggle()
        env.monitorRunner.setPaused(env.preferences.paused)
        sender.state = env.preferences.paused ? .on : .off
    }

    @objc private func openSettings() {
        environment?.presentSettings(reusing: &settingsWindow)
    }
}
