// Core/Tests/ClipKeepCoreTests/CaptureCoordinatorTests.swift
import XCTest
@testable import ClipKeepCore

final class CaptureCoordinatorTests: XCTestCase {
    private func makeCoordinator() throws -> (CaptureCoordinator, HistoryStore, AppPaths) {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ck-cap-\(UUID().uuidString)", isDirectory: true)
        let paths = AppPaths(root: root)
        try paths.ensureDirectories()
        let store = try HistoryStore(inMemory: true)
        let config = CaptureConfig(maxImageBytes: 50 * 1024 * 1024,
                                   thumbnailMaxPixel: 64,
                                   excludedBundleIDs: ["com.agilebits.onepassword7"])
        let coordinator = CaptureCoordinator(store: store,
                                             imageStore: ImageStore(paths: paths),
                                             filter: PrivacyFilter(),
                                             extractor: ClipExtractor(),
                                             config: config)
        return (coordinator, store, paths)
    }

    func test_capturesText() throws {
        let (coord, store, paths) = try makeCoordinator()
        defer { try? FileManager.default.removeItem(at: paths.root) }
        let pb = FakePasteboard(); pb.setText("captured text")
        try coord.capture(reader: pb, sourceBundleID: "com.apple.Safari", now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(try store.recent(limit: 10).first?.text, "captured text")
    }

    func test_skipsConcealed() throws {
        let (coord, store, paths) = try makeCoordinator()
        defer { try? FileManager.default.removeItem(at: paths.root) }
        let pb = FakePasteboard()
        pb.setRaw(types: [PasteboardType.utf8PlainText, PasteboardType.concealed],
                  strings: [PasteboardType.utf8PlainText: "s3cret"])
        try coord.capture(reader: pb, sourceBundleID: nil, now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(try store.recent(limit: 10).count, 0)
    }

    func test_skipsExcludedApp() throws {
        let (coord, store, paths) = try makeCoordinator()
        defer { try? FileManager.default.removeItem(at: paths.root) }
        let pb = FakePasteboard(); pb.setText("from 1password")
        try coord.capture(reader: pb, sourceBundleID: "com.agilebits.onepassword7", now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(try store.recent(limit: 10).count, 0)
    }

    func test_capturesImage_writesFile_andStoresMetadata() throws {
        let (coord, store, paths) = try makeCoordinator()
        defer { try? FileManager.default.removeItem(at: paths.root) }
        let pb = FakePasteboard(); pb.setPNG(TestImages.pngData(width: 40, height: 25))
        try coord.capture(reader: pb, sourceBundleID: nil, now: Date(timeIntervalSince1970: 1))
        let clip = try XCTUnwrap(try store.recent(limit: 10).first)
        XCTAssertEqual(clip.kind, .image)
        XCTAssertEqual(clip.width, 40); XCTAssertEqual(clip.height, 25)
        let file = try XCTUnwrap(clip.imageFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.imagesDir.appendingPathComponent(file).path))
    }

    func test_skipsOversizeImage() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ck-big-\(UUID().uuidString)", isDirectory: true)
        let paths = AppPaths(root: root); try paths.ensureDirectories()
        defer { try? FileManager.default.removeItem(at: paths.root) }
        let store = try HistoryStore(inMemory: true)
        let config = CaptureConfig(maxImageBytes: 10, thumbnailMaxPixel: 64, excludedBundleIDs: [])
        let coord = CaptureCoordinator(store: store, imageStore: ImageStore(paths: paths),
                                       filter: PrivacyFilter(), extractor: ClipExtractor(), config: config)
        let pb = FakePasteboard(); pb.setPNG(TestImages.pngData(width: 100, height: 100))  // > 10 bytes
        try coord.capture(reader: pb, sourceBundleID: nil, now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(try store.recent(limit: 10).count, 0)
    }
}
