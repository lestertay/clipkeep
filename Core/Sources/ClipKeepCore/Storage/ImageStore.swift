import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

public struct StoredImage: Equatable {
    public let imageFile: String
    public let thumbFile: String
    public let width: Int
    public let height: Int
    public let byteSize: Int
}

public enum ImageStoreError: Error { case decodeFailed, thumbnailFailed, encodeFailed }

public struct ImageStore {
    private let paths: AppPaths
    public init(paths: AppPaths) { self.paths = paths }

    /// Persist full PNG to imagesDir and a downscaled JPEG thumbnail to thumbsDir.
    public func write(pngData: Data, maxThumbnailPixel: Int) throws -> StoredImage {
        guard let src = CGImageSourceCreateWithData(pngData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw ImageStoreError.decodeFailed
        }
        let uuid = UUID().uuidString
        let imageFile = "\(uuid).png"
        let thumbFile = "\(uuid).jpg"

        try pngData.write(to: paths.imagesDir.appendingPathComponent(imageFile))

        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxThumbnailPixel,
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, thumbOptions as CFDictionary) else {
            throw ImageStoreError.thumbnailFailed
        }
        let thumbData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(thumbData, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw ImageStoreError.encodeFailed
        }
        CGImageDestinationAddImage(dest, thumb, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { throw ImageStoreError.encodeFailed }
        try (thumbData as Data).write(to: paths.thumbsDir.appendingPathComponent(thumbFile))

        return StoredImage(imageFile: imageFile, thumbFile: thumbFile,
                           width: image.width, height: image.height, byteSize: pngData.count)
    }

    public func deleteFiles(_ names: [String]) {
        let fm = FileManager.default
        for name in names {
            try? fm.removeItem(at: paths.imagesDir.appendingPathComponent(name))
            try? fm.removeItem(at: paths.thumbsDir.appendingPathComponent(name))
        }
    }
}
