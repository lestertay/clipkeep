// App/Sources/Popup/CaretLocator.swift
import AppKit
import ApplicationServices

/// Best-effort anchor for the popup, via the Accessibility API:
///   1. the text insertion caret of the focused element (works in native fields, and in
///      Chromium/Electron apps once their accessibility tree is enabled — see below),
///   2. else the focused element's frame (so we still open near the field),
///   3. else nil, and the caller falls back to the mouse.
/// Returns a rect in Cocoa global screen coordinates (bottom-left origin).
enum CaretLocator {
    static func anchorRect() -> CGRect? {
        let system = AXUIElementCreateSystemWide()

        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
              let focusedRef else { return nil }
        let element = focusedRef as! AXUIElement

        // Electron/Chromium keep accessibility off until asked. Setting AXManualAccessibility
        // on the owning app turns it on; the tree builds asynchronously, so the caret may only
        // become available on a subsequent open — but after that the path below works.
        enableChromiumAccessibility(for: element)

        if let caret = caretRect(of: element) { return caret }
        if let frame = elementFrame(of: element) { return frame }
        return nil
    }

    private static func caretRect(of element: AXUIElement) -> CGRect? {
        var rangeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeRef) == .success,
              let rangeRef else { return nil }

        var boundsRef: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
                element, kAXBoundsForRangeParameterizedAttribute as CFString, rangeRef as! AXValue, &boundsRef) == .success,
              let boundsRef else { return nil }

        var cg = CGRect.zero
        guard AXValueGetValue(boundsRef as! AXValue, .cgRect, &cg), cg.width > 0 || cg.height > 0 else { return nil }
        return cocoaRect(fromCGScreen: cg)
    }

    private static func elementFrame(of element: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success, let posRef,
              AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success, let sizeRef
        else { return nil }

        var pos = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(posRef as! AXValue, .cgPoint, &pos),
              AXValueGetValue(sizeRef as! AXValue, .cgSize, &size),
              size.width > 0, size.height > 0 else { return nil }
        return cocoaRect(fromCGScreen: CGRect(origin: pos, size: size))
    }

    /// Ask a Chromium/Electron app to enable its accessibility tree. No-op for other apps.
    private static func enableChromiumAccessibility(for element: AXUIElement) {
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success else { return }
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
    }

    /// Convert a CG global rect (top-left origin, y-down) to Cocoa global (bottom-left, y-up),
    /// flipped about the primary display (the screen whose Cocoa frame origin is (0,0)).
    private static func cocoaRect(fromCGScreen cg: CGRect) -> CGRect? {
        guard let primaryHeight = (NSScreen.screens.first { $0.frame.origin == .zero }?.frame.height)
                ?? NSScreen.main?.frame.height else { return nil }
        return CGRect(x: cg.origin.x, y: primaryHeight - cg.origin.y - cg.height, width: cg.width, height: cg.height)
    }
}
