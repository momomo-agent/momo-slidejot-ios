import SwiftUI

@main
struct SlideJotApp: App {
    @StateObject private var db = DatabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(db)
                .task {
                    await db.setup()
                }
        }
    }
}
