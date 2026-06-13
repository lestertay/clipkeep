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
        return m
    }

    /// Insert a clip. (De-duplication added in Task 2.2.)
    @discardableResult
    public func record(_ clip: Clip) throws -> Clip {
        try dbQueue.write { db in
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
}
