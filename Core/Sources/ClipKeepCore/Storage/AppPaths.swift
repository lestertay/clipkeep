import Foundation

public struct AppPaths {
    public let root: URL
    public var databaseURL: URL { root.appendingPathComponent("history.sqlite") }
    public var imagesDir: URL { root.appendingPathComponent("images", isDirectory: true) }
    public var thumbsDir: URL { root.appendingPathComponent("thumbs", isDirectory: true) }

    public init(root: URL) { self.root = root }

    /// Default location: ~/Library/Application Support/ClipKeep
    public static func standard(bundleName: String = "ClipKeep") -> AppPaths {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return AppPaths(root: base.appendingPathComponent(bundleName, isDirectory: true))
    }

    public func ensureDirectories() throws {
        let fm = FileManager.default
        for dir in [root, imagesDir, thumbsDir] {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}
