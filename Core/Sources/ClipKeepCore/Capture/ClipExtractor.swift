// Core/Sources/ClipKeepCore/Capture/ClipExtractor.swift
import Foundation
import ImageIO

public enum ExtractedClip {
    case text(text: String, preview: String, hash: String)
    case image(data: Data, width: Int, height: Int, hash: String)
}

public struct ClipExtractor {
    public init() {}

    public func extract(from reader: PasteboardReading) -> ExtractedClip? {
        let types = Set(reader.types())

        // Prefer image when present (screenshots often carry both image + text promises).
        for imageType in [PasteboardType.png, PasteboardType.tiff] where types.contains(imageType) {
            if let data = reader.data(forType: imageType),
               let dims = Self.dimensions(of: data) {
                // PNG input is already the canonical format; only re-encode TIFF (and others).
                let png = (imageType == PasteboardType.png) ? data : (Self.normalizedPNG(from: data) ?? data)
                return .image(data: png, width: dims.width, height: dims.height,
                              hash: Hashing.sha256(data: png))
            }
        }

        if types.contains(PasteboardType.utf8PlainText),
           let raw = reader.string(forType: PasteboardType.utf8PlainText) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let preview = String(trimmed.prefix(200))
            return .text(text: raw, preview: preview, hash: Hashing.sha256(text: raw))
        }
        return nil
    }

    private static func dimensions(of data: Data) -> (width: Int, height: Int)? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (w, h)
    }

    /// Re-encode TIFF (or anything) to PNG so the on-disk format is consistent.
    private static func normalizedPNG(from data: Data) -> Data? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return out as Data
    }
}
