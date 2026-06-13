// App/Sources/ClipKeepApp.swift
import AppKit

@main
enum ClipKeepMain {
    @MainActor static let delegate = AppDelegate()
    @MainActor static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory)   // no Dock icon; matches LSUIElement
        app.run()
    }
}
