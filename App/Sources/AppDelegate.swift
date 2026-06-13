// App/Sources/AppDelegate.swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let env = AppEnvironment()
        environment = env

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                     accessibilityDescription: "ClipKeep")
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit ClipKeep",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item

        env.start()
    }
}
