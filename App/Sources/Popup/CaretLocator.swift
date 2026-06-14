// App/Sources/Popup/CaretLocator.swift
import AppKit
import ApplicationServices

/// Best-effort location of the text insertion caret in the currently focused UI element,
/// via the Accessibility API. Returns the caret rect in Cocoa global screen coordinates
/// (bottom-left origin), or nil when the focused app doesn't expose caret geometry
/// (e.g. some Electron apps, terminals, or web inputs) — callers should fall back.
enum CaretLocator {
    static func caretRect() -> CGRect? {
        let system = AXUIElementCreateSystemWide()

        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
              let focusedRef else { return nil }
        let element = focusedRef as! AXUIElement

        // The caret is the selected text range (usually zero-length).
        var rangeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
              let rangeRef else { return nil }
        let axRange = rangeRef as! AXValue

        // Bounds for that range, in CG global screen coords (top-left origin, y-down).
        var boundsRef: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
                element, kAXBoundsForRangeParameterizedAttribute as CFString, axRange, &boundsRef) == .success,
              let boundsRef else { return nil }
        var cgRect = CGRect.zero
        guard AXValueGetValue(boundsRef as! AXValue, .cgRect, &cgRect) else { return nil }

        // A degenerate all-zero rect means there's no usable caret geometry.
        guard cgRect.height > 0 || cgRect.width > 0 else { return nil }

        return cocoaRect(fromCGScreen: cgRect)
    }

    /// Convert a CG global rect (top-left origin, y-down) to Cocoa global (bottom-left, y-up).
    /// The flip is relative to the primary display (the screen whose Cocoa frame origin is (0,0)).
    private static func cocoaRect(fromCGScreen cg: CGRect) -> CGRect? {
        guard let primaryHeight = (NSScreen.screens.first { $0.frame.origin == .zero }?.frame.height)
                ?? NSScreen.main?.frame.height else { return nil }
        let flippedY = primaryHeight - cg.origin.y - cg.height
        return CGRect(x: cg.origin.x, y: flippedY, width: cg.width, height: cg.height)
    }
}
