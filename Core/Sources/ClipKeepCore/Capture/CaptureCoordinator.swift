// Core/Sources/ClipKeepCore/Capture/CaptureCoordinator.swift
import Foundation

public struct CaptureConfig {
    public var maxImageBytes: Int
    public var thumbnailMaxPixel: Int
    public var excludedBundleIDs: Set<String>
    public init(maxImageBytes: Int, thumbnailMaxPixel: Int, excludedBundleIDs: Set<String>) {
        self.maxImageBytes = maxImageBytes
        self.thumbnailMaxPixel = thumbnailMaxPixel
        self.excludedBundleIDs = excludedBundleIDs
    }
}

/// `@unchecked Sendable`: holds a `Sendable` `HistoryStore`, a value-type `ImageStore`
/// (URLs only), and value-type filter/extractor/config. All stored properties are `let`.
public final class CaptureCoordinator: @unchecked Sendable {
    private let store: HistoryStore
    private let imageStore: ImageStore
    private let filter: PrivacyFilter
    private let extractor: ClipExtractor
    private let config: CaptureConfig

    public init(store: HistoryStore, imageStore: ImageStore,
                filter: PrivacyFilter, extractor: ClipExtractor, config: CaptureConfig) {
        self.store = store
        self.imageStore = imageStore
        self.filter = filter
        self.extractor = extractor
        self.config = config
    }

    public func capture(reader: PasteboardReading, sourceBundleID: String?, now: Date) throws {
        guard filter.shouldCapture(types: reader.types(),
                                   sourceBundleID: sourceBundleID,
                                   excludedBundleIDs: config.excludedBundleIDs) else { return }
        guard let extracted = extractor.extract(from: reader) else { return }

        switch extracted {
        case .text(let text, let preview, let hash):
            let clip = Clip(kind: .text, text: text, preview: preview,
                            contentHash: hash, sourceBundleID: sourceBundleID,
                            createdAt: now, lastUsedAt: now)
            try store.record(clip)

        case .image(let data, let width, let height, let hash):
            guard data.count <= config.maxImageBytes else { return }
            let stored = try imageStore.write(pngData: data, maxThumbnailPixel: config.thumbnailMaxPixel)
            let clip = Clip(kind: .image, preview: "Image \(width)×\(height)",
                            imageFile: stored.imageFile, thumbFile: stored.thumbFile,
                            width: width, height: height, byteSize: stored.byteSize,
                            contentHash: hash, sourceBundleID: sourceBundleID,
                            createdAt: now, lastUsedAt: now)
            try store.record(clip)
        }
    }

    /// Convenience used by the app after each capture. Returns image files removed (already deleted from disk).
    @discardableResult
    public func runRetentionSweep(store: HistoryStore, imageStore: ImageStore,
                                  maxCount: Int, maxAge: TimeInterval, maxImageBytes: Int) throws -> [String] {
        var removed = try store.prune(maxCount: maxCount, maxAge: maxAge, now: Date())
        removed += try store.pruneImages(maxTotalBytes: maxImageBytes)
        imageStore.deleteFiles(removed)
        return removed
    }
}
