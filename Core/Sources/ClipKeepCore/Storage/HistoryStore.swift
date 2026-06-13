// Core/Sources/ClipKeepCore/Storage/HistoryStore.swift
import Foundation
import GRDB

extension Clip: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "clip"
    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

public final class HistoryStore {
    private let dbQueue: DatabaseQueue

    public init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        try Self.migrator.migrate(dbQueue)
    }

    public init(inMemory: Bool) throws {
        precondition(inMemory)
        dbQueue = try DatabaseQueue()           // in-memory
        try Self.migrator.migrate(dbQueue)
    }

    private static var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.create(table: "clip") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("kind", .text).notNull()
                t.column("text", .text)
                t.column("preview", .text).notNull()
                t.column("imageFile", .text)
                t.column("thumbFile", .text)
                t.column("width", .integer)
                t.column("height", .integer)
                t.column("byteSize", .integer)
                t.column("contentHash", .text).notNull()
                t.column("sourceBundleID", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("lastUsedAt", .datetime).notNull()
            }
            try db.create(index: "clip_lastUsedAt", on: "clip", columns: ["lastUsedAt"])
        }
        m.registerMigration("v2_fts") { db in
            try db.create(virtualTable: "clip_ft", using: FTS5()) { t in
                t.synchronize(withTable: "clip")
                t.column("text")
                t.column("preview")
            }
        }
        return m
    }

    public func mostRecent() throws -> Clip? {
        try dbQueue.read { db in
            try Clip.order(Column("lastUsedAt").desc).fetchOne(db)
        }
    }

    /// Insert, or if the content matches the most-recent clip, bump it to the top.
    @discardableResult
    public func record(_ clip: Clip) throws -> Clip {
        try dbQueue.write { db in
            if let latest = try Clip.order(Column("lastUsedAt").desc).fetchOne(db),
               latest.contentHash == clip.contentHash {
                var updated = latest
                updated.lastUsedAt = clip.lastUsedAt
                try updated.update(db)
                return updated
            }
            var c = clip
            try c.insert(db)
            return c
        }
    }

    public func recent(limit: Int) throws -> [Clip] {
        try dbQueue.read { db in
            try Clip.order(Column("lastUsedAt").desc).limit(limit).fetchAll(db)
        }
    }

    /// Remove clips beyond `maxCount` (keeping newest by lastUsedAt) or older than `maxAge`
    /// seconds. Returns image/thumb filenames of removed clips for on-disk cleanup.
    @discardableResult
    public func prune(maxCount: Int, maxAge: TimeInterval, now: Date) throws -> [String] {
        try dbQueue.write { db in
            let cutoff = now.addingTimeInterval(-maxAge)
            let all = try Clip.order(Column("lastUsedAt").desc).fetchAll(db)

            var toDelete: [Clip] = []
            for (index, clip) in all.enumerated() {
                let tooOld = maxAge.isFinite && clip.lastUsedAt < cutoff
                let overCount = index >= maxCount
                if tooOld || overCount { toDelete.append(clip) }
            }
            for clip in toDelete {
                if let id = clip.id { _ = try Clip.deleteOne(db, key: id) }
            }
            return toDelete.flatMap { [$0.imageFile, $0.thumbFile].compactMap { $0 } }
        }
    }

    /// Delete one clip; returns the image/thumb filenames that should be removed from disk.
    @discardableResult
    public func delete(id: Int64) throws -> [String] {
        try dbQueue.write { db in
            guard let clip = try Clip.fetchOne(db, key: id) else { return [] }
            _ = try Clip.deleteOne(db, key: id)
            return [clip.imageFile, clip.thumbFile].compactMap { $0 }
        }
    }

    /// Delete everything; returns all image/thumb filenames to remove from disk.
    @discardableResult
    public func clearAll() throws -> [String] {
        try dbQueue.write { db in
            let files = try Clip.fetchAll(db).flatMap { [$0.imageFile, $0.thumbFile].compactMap { $0 } }
            _ = try Clip.deleteAll(db)
            return files
        }
    }

    public func search(_ rawQuery: String, limit: Int) throws -> [Clip] {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try recent(limit: limit) }

        // Build a prefix MATCH pattern: each token becomes `"token"*`.
        let pattern = trimmed
            .split(whereSeparator: { $0 == " " })
            .map { token -> String in
                let escaped = token.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\"*"
            }
            .joined(separator: " ")

        return try dbQueue.read { db in
            let sql = """
                SELECT clip.* FROM clip
                JOIN clip_ft ON clip_ft.rowid = clip.id
                WHERE clip_ft MATCH ?
                ORDER BY clip.lastUsedAt DESC
                LIMIT ?
                """
            return try Clip.fetchAll(db, sql: sql, arguments: [pattern, limit])
        }
    }
}
