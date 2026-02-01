import Foundation
import GRDB

enum StorageMode: String {
    case local
    case macSync
    
    var title: String {
        switch self {
        case .local: return "仅本机"
        case .macSync: return "Mac 同步（模拟器）"
        }
    }
    
    var subtitle: String {
        switch self {
        case .local: return "数据仅保存在本设备"
        case .macSync: return "直接读取 Mac 版 SlideJot 数据库"
        }
    }
}

@MainActor
final class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    @Published var jots: [Jot] = []
    @Published var isLoading = true
    @Published var currentMode: StorageMode = .local
    
    private var dbQueue: DatabaseQueue?
    private var observer: DatabaseCancellable?
    private static let storageModeKey = "storage_mode"
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.storageModeKey),
           let mode = StorageMode(rawValue: saved) {
            currentMode = mode
        } else {
            #if targetEnvironment(simulator)
            currentMode = .macSync
            #else
            currentMode = .local
            #endif
        }
    }
    
    func setStorageMode(_ mode: StorageMode) {
        currentMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: Self.storageModeKey)
    }
    
    func setup() async {
        do {
            let dbPath = try getDatabasePath()
            var config = Configuration()
            config.readonly = (currentMode == .macSync)
            dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            
            if !config.readonly {
                try await createTablesIfNeeded()
            }
            await startObserving()
            await loadJots()
            isLoading = false
        } catch {
            print("Database setup failed: \(error)")
            isLoading = false
        }
    }
    
    private func getDatabasePath() throws -> String {
        switch currentMode {
        case .macSync:
            #if targetEnvironment(simulator)
            let macDB = NSString(string: "~/Library/Application Support/SlideJot/jots.db").expandingTildeInPath
            if FileManager.default.fileExists(atPath: macDB) {
                return macDB
            }
            #endif
            fallthrough
        case .local:
            let localURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return localURL.appendingPathComponent("jots.db").path
        }
    }
    
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
    
    private func startObserving() async {
        guard let dbQueue else { return }
        observer = ValueObservation
            .tracking { db in try Jot.fetchAll(db) }
            .start(in: dbQueue, onError: { error in
                print("Observation error: \(error)")
            }, onChange: { [weak self] jots in
                Task { @MainActor in self?.jots = jots }
            })
    }
    
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
            try await dbQueue?.write { db in try jot.insert(db) }
            return jot
        } catch {
            print("Create jot failed: \(error)")
            return nil
        }
    }
    
    func updateJot(_ jot: Jot, content: String) async {
        var updated = jot
        updated.content = content
        updated.updatedAt = Date().timeIntervalSince1970
        do {
            try await dbQueue?.write { db in try updated.update(db) }
        } catch {
            print("Update jot failed: \(error)")
        }
    }
    
    func trashJot(_ jot: Jot) async {
        var trashed = jot
        trashed.trashedAt = Date().timeIntervalSince1970
        do {
            try await dbQueue?.write { db in try trashed.update(db) }
        } catch {
            print("Trash jot failed: \(error)")
        }
    }
}
