import Foundation
import GRDB

/// 管理 SQLite 数据库，支持 iCloud 同步
@MainActor
final class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    @Published var jots: [Jot] = []
    @Published var isLoading = true
    
    private var dbQueue: DatabaseQueue?
    private var observer: DatabaseCancellable?
    
    private init() {}
    
    /// 初始化数据库
    func setup() async {
        do {
            let dbPath = try getDatabasePath()
            dbQueue = try DatabaseQueue(path: dbPath)
            try await createTablesIfNeeded()
            await startObserving()
            await loadJots()
            isLoading = false
        } catch {
            print("Database setup failed: \(error)")
            isLoading = false
        }
    }
    
    /// 获取数据库路径
    private func getDatabasePath() throws -> String {
        #if targetEnvironment(simulator)
        // 模拟器：直接读取 Mac 版数据库
        let macDB = NSString(string: "~/Library/Application Support/SlideJot/jots.db")
            .expandingTildeInPath
        if FileManager.default.fileExists(atPath: macDB) {
            print("📱 Using Mac database: \(macDB)")
            return macDB
        }
        #endif
        
        // 真机：尝试 iCloud
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents") {
            try FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
            return iCloudURL.appendingPathComponent("jots.db").path
        }
        
        // 回退到本地
        let localURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SlideJot")
        try FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true)
        return localURL.appendingPathComponent("jots.db").path
    }
    
    /// 创建表结构（兼容 Mac 版）
    private func createTablesIfNeeded() async throws {
        try await dbQueue?.write { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS jots (
                    id TEXT PRIMARY KEY,
                    content TEXT NOT NULL DEFAULT '',
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL,
                    trashed_at REAL,
                    pinned_at REAL
                )
            """)
        }
    }
    
    /// 监听数据库变化
    private func startObserving() async {
        guard let dbQueue else { return }
        observer = ValueObservation
            .tracking { db in
                try Jot.fetchAll(db)
            }
            .start(in: dbQueue, onError: { error in
                print("Observation error: \(error)")
            }, onChange: { [weak self] jots in
                Task { @MainActor in
                    self?.jots = jots
                }
            })
    }
    
    /// 加载所有 jots
    private func loadJots() async {
        do {
            jots = try await dbQueue?.read { db in
                try Jot.filter(Column("trashed_at") == nil)
                    .order(Column("pinned_at").desc, Column("updated_at").desc)
                    .fetchAll(db)
            } ?? []
        } catch {
            print("Load jots failed: \(error)")
        }
    }
    
    // MARK: - CRUD
    
    /// 创建新 jot
    func createJot(content: String = "") async -> Jot? {
        let now = Date().timeIntervalSince1970
        let jot = Jot(
            id: UUID().uuidString.uppercased(),
            content: content,
            createdAt: now,
            updatedAt: now,
            trashedAt: nil,
            pinnedAt: nil
        )
        
        do {
            try await dbQueue?.write { db in
                try jot.insert(db)
            }
            return jot
        } catch {
            print("Create jot failed: \(error)")
            return nil
        }
    }
    
    /// 更新 jot 内容
    func updateJot(_ jot: Jot, content: String) async {
        var updated = jot
        updated.content = content
        updated.updatedAt = Date().timeIntervalSince1970
        
        do {
            try await dbQueue?.write { db in
                try updated.update(db)
            }
        } catch {
            print("Update jot failed: \(error)")
        }
    }
    
    /// 删除 jot（移到回收站）
    func trashJot(_ jot: Jot) async {
        var trashed = jot
        trashed.trashedAt = Date().timeIntervalSince1970
        
        do {
            try await dbQueue?.write { db in
                try trashed.update(db)
            }
        } catch {
            print("Trash jot failed: \(error)")
        }
    }
    
    /// 切换置顶状态
    func togglePin(_ jot: Jot) async {
        var updated = jot
        updated.pinnedAt = jot.pinnedAt == nil ? Date().timeIntervalSince1970 : nil
        updated.updatedAt = Date().timeIntervalSince1970
        
        do {
            try await dbQueue?.write { db in
                try updated.update(db)
            }
        } catch {
            print("Toggle pin failed: \(error)")
        }
    }
}
