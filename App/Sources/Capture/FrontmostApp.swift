// App/Sources/Capture/FrontmostApp.swift
import AppKit

enum FrontmostApp {
    static func bundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
    static func current() -> NSRunningApplication? {
        NSWorkspace.shared.frontmostApplication
    }
}
