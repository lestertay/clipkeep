import XCTest
@testable import ClipKeepCore

final class RetentionSweepTests: XCTestCase {
    func test_sweep_prunesCountThenImages() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ck-sweep-\(UUID().uuidString)", isDirectory: true)
        let paths = AppPaths(root: root); try paths.ensureDirectories()
        defer { try? FileManager.default.removeItem(at: paths.root) }
        let store = try HistoryStore(inMemory: true)
        let imageStore = ImageStore(paths: paths)
        let coord = CaptureCoordinator(store: store, imageStore: imageStore,
                                       filter: PrivacyFilter(), extractor: ClipExtractor(),
                                       config: CaptureConfig(maxImageBytes: 50_000_000, thumbnailMaxPixel: 64, excludedBundleIDs: []))
        for i in 1...10 {
            _ = try store.record(Clip(kind: .text, text: "c\(i)", preview: "c\(i)", contentHash: "h\(i)",
                                      createdAt: Date(timeIntervalSince1970: TimeInterval(i)),
                                      lastUsedAt: Date(timeIntervalSince1970: TimeInterval(i))))
        }
        _ = try coord.runRetentionSweep(store: store, imageStore: imageStore, maxCount: 4, maxAge: .infinity, maxImageBytes: 1_000_000_000)
        XCTAssertEqual(try store.recent(limit: 50).count, 4)
    }
}
