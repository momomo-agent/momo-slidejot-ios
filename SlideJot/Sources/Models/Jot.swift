import Foundation
import GRDB

/// Jot 数据模型，兼容 Mac 版 SQLite 结构
struct Jot: Identifiable, Codable, Hashable {
    var id: String
    var content: String
    var createdAt: Double  // Unix timestamp
    var updatedAt: Double
    var trashedAt: Double?
    var pinnedAt: Double?
    
    var isPinned: Bool { pinnedAt != nil }
    var isTrashed: Bool { trashedAt != nil }
    
    var createdDate: Date { Date(timeIntervalSince1970: createdAt) }
    var updatedDate: Date { Date(timeIntervalSince1970: updatedAt) }
}

// MARK: - GRDB
extension Jot: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "jots" }
    
    enum Columns: String, ColumnExpression {
        case id, content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case trashedAt = "trashed_at"
        case pinnedAt = "pinned_at"
    }
    
    init(row: Row) {
        id = row["id"]
        content = row["content"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
        trashedAt = row["trashed_at"]
        pinnedAt = row["pinned_at"]
    }
    
    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["content"] = content
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
        container["trashed_at"] = trashedAt
        container["pinned_at"] = pinnedAt
    }
}
