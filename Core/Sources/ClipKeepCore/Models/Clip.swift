// Core/Sources/ClipKeepCore/Models/Clip.swift
import Foundation

public enum ClipKind: String, Codable, Sendable {
    case text
    case image
}

public struct Clip: Identifiable, Equatable, Sendable, Codable {
    public var id: Int64?
    public var kind: ClipKind
    public var text: String?
    public var preview: String
    public var imageFile: String?
    public var thumbFile: String?
    public var width: Int?
    public var height: Int?
    public var byteSize: Int?
    public var contentHash: String
    public var sourceBundleID: String?
    public var createdAt: Date
    public var lastUsedAt: Date

    public init(id: Int64? = nil,
                kind: ClipKind,
                text: String? = nil,
                preview: String,
                imageFile: String? = nil,
                thumbFile: String? = nil,
                width: Int? = nil,
                height: Int? = nil,
                byteSize: Int? = nil,
                contentHash: String,
                sourceBundleID: String? = nil,
                createdAt: Date,
                lastUsedAt: Date) {
        self.id = id
        self.kind = kind
        self.text = text
        self.preview = preview
        self.imageFile = imageFile
        self.thumbFile = thumbFile
        self.width = width
        self.height = height
        self.byteSize = byteSize
        self.contentHash = contentHash
        self.sourceBundleID = sourceBundleID
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
    }
}
