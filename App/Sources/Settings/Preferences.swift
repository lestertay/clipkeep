// App/Sources/Settings/Preferences.swift
import Foundation
import Combine

/// Where the history popup appears when summoned.
enum PopupPosition: String, CaseIterable, Identifiable {
    case caret, mouse, center, lastPosition
    var id: String { rawValue }
    var label: String {
        switch self {
        case .caret: return "Text caret"
        case .mouse: return "Mouse pointer"
        case .center: return "Screen center"
        case .lastPosition: return "Last position"
        }
    }
}

final class Preferences: ObservableObject {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        register()
    }

    private func register() {
        defaults.register(defaults: [
            Keys.maxCount: 500,
            Keys.maxAgeDays: 30,
            Keys.maxImageMB: 1024,
            Keys.maxSingleImageMB: 50,
            Keys.respectConcealed: true,
            Keys.excludedBundleIDs: [String](),
            Keys.paused: false,
            Keys.popupPosition: PopupPosition.caret.rawValue,
        ])
    }

    enum Keys {
        static let maxCount = "maxCount"
        static let maxAgeDays = "maxAgeDays"
        static let maxImageMB = "maxImageMB"
        static let maxSingleImageMB = "maxSingleImageMB"
        static let respectConcealed = "respectConcealed"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let paused = "paused"
        static let popupPosition = "popupPosition"
    }

    var maxCount: Int { get { defaults.integer(forKey: Keys.maxCount) } set { defaults.set(newValue, forKey: Keys.maxCount) } }
    var maxAgeDays: Int { get { defaults.integer(forKey: Keys.maxAgeDays) } set { defaults.set(newValue, forKey: Keys.maxAgeDays) } }
    var maxImageMB: Int { get { defaults.integer(forKey: Keys.maxImageMB) } set { defaults.set(newValue, forKey: Keys.maxImageMB) } }
    var maxSingleImageMB: Int { get { defaults.integer(forKey: Keys.maxSingleImageMB) } set { defaults.set(newValue, forKey: Keys.maxSingleImageMB) } }
    var excludedBundleIDs: [String] { get { defaults.stringArray(forKey: Keys.excludedBundleIDs) ?? [] } set { defaults.set(newValue, forKey: Keys.excludedBundleIDs) } }
    var paused: Bool { get { defaults.bool(forKey: Keys.paused) } set { defaults.set(newValue, forKey: Keys.paused) } }
    var popupPosition: String { get { defaults.string(forKey: Keys.popupPosition) ?? PopupPosition.caret.rawValue } set { defaults.set(newValue, forKey: Keys.popupPosition) } }

    var maxAge: TimeInterval { TimeInterval(maxAgeDays) * 86_400 }
    var maxImageBytes: Int { maxImageMB * 1024 * 1024 }
    var maxSingleImageBytes: Int { maxSingleImageMB * 1024 * 1024 }
}
