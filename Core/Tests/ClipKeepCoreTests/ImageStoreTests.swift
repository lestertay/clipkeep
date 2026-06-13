import XCTest
import ImageIO
@testable import ClipKeepCore

final class ImageStoreTests: XCTestCase {
    private func makePaths() throws -> AppPaths {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ck-img-\(UUID().uuidString)", isDirectory: true)
        let paths = AppPaths(root: root)
        try paths.ensureDirectories()
        return paths
    }

    func test_write_storesImageAndThumbnail_andReportsDimensions() throws {
        let paths = try makePaths()
        defer { try? FileManager.default.removeItem(at: paths.root) }
        let store = ImageStore(paths: paths)

        let png = TestImages.pngData(width: 200, height: 120)
        let result = try store.write(pngData: png, maxThumbnailPixel: 64)

        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 120)
        XCTAssertGreaterThan(result.byteSize, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.imagesDir.appendingPathComponent(result.imageFile).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.thumbsDir.appendingPathComponent(result.thumbFile).path))
    }

    func test_delete_removesNamedFiles() throws {
        let paths = try makePaths()
        defer { try? FileManager.default.removeItem(at: paths.root) }
        let store = ImageStore(paths: paths)
        let result = try store.write(pngData: TestImages.pngData(width: 20, height: 20), maxThumbnailPixel: 64)

        store.deleteFiles([result.imageFile, result.thumbFile])
        XCTAssertFalse(FileManager.default.fileExists(atPath: paths.imagesDir.appendingPathComponent(result.imageFile).path))
    }
}
