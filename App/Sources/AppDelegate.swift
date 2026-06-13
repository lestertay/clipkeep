// App/Sources/AppDelegate.swift
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var environment: AppEnvironment?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

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
        maybeShowOnboarding()
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

    private func maybeShowOnboarding() {
        let key = "didOnboard"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let view = OnboardingView(
            onGrant: { AccessibilityAuthorizer.promptIfNeeded(); AccessibilityAuthorizer.openSettingsPane() },
            onContinue: { [weak self] in
                UserDefaults.standard.set(true, forKey: key)
                self?.onboardingWindow?.close(); self?.onboardingWindow = nil
            }
        )
        let win = NSWindow(contentViewController: NSHostingController(rootView: view))
        win.title = "Welcome"
        win.styleMask = [.titled, .closable]
        win.isReleasedWhenClosed = false
        win.center(); win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = win
    }
}
