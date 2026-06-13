// Core/Tests/ClipKeepCoreTests/ClipExtractorTests.swift
import XCTest
@testable import ClipKeepCore

final class ClipExtractorTests: XCTestCase {
    private let extractor = ClipExtractor()

    func test_extractsText_withPreviewAndHash() {
        let pb = FakePasteboard()
        pb.setText("  hello world  ")
        let result = extractor.extract(from: pb)
        guard case .text(let text, let preview, let hash)? = result else {
            return XCTFail("expected text")
        }
        XCTAssertEqual(text, "  hello world  ")
        XCTAssertEqual(preview, "hello world")          // trimmed for display
        XCTAssertEqual(hash, Hashing.sha256(text: "  hello world  "))
    }

    func test_emptyOrWhitespaceText_isIgnored() {
        let pb = FakePasteboard()
        pb.setText("   \n  ")
        XCTAssertNil(extractor.extract(from: pb))
    }

    func test_extractsImage_withDimensionsAndHash() {
        let pb = FakePasteboard()
        let png = TestImages.pngData(width: 30, height: 20)
        pb.setPNG(png)
        let result = extractor.extract(from: pb)
        guard case .image(let data, let w, let h, let hash)? = result else {
            return XCTFail("expected image")
        }
        XCTAssertEqual(data, png)
        XCTAssertEqual(w, 30); XCTAssertEqual(h, 20)
        XCTAssertEqual(hash, Hashing.sha256(data: png))
    }

    func test_unknownTypes_areIgnored() {
        let pb = FakePasteboard()
        pb.setRaw(types: ["com.apple.pasteboard.promised-file-url"])
        XCTAssertNil(extractor.extract(from: pb))
    }
}
