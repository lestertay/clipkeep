import XCTest
@testable import ClipKeepCore

final class AppPathsTests: XCTestCase {
    func test_paths_areNestedUnderRoot() {
        let root = URL(fileURLWithPath: "/tmp/ck-test-root", isDirectory: true)
        let paths = AppPaths(root: root)
        XCTAssertEqual(paths.databaseURL.lastPathComponent, "history.sqlite")
        XCTAssertTrue(paths.imagesDir.path.hasPrefix(root.path))
        XCTAssertEqual(paths.imagesDir.lastPathComponent, "images")
        XCTAssertEqual(paths.thumbsDir.lastPathComponent, "thumbs")
    }

    func test_ensureDirectories_createsThem() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ck-\(UUID().uuidString)", isDirectory: true)
        let paths = AppPaths(root: root)
        try paths.ensureDirectories()
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.imagesDir.path, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
        try? FileManager.default.removeItem(at: root)
    }
}
