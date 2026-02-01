import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var db: DatabaseManager
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    
    private var jots: [Jot] {
        db.jots.filter { !$0.isTrashed }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                if db.isLoading {
                    ProgressView()
                } else if jots.isEmpty {
                    EmptyStateView(onCreateNew: createNewJot)
                } else {
                    CardStackView(
                        jots: jots,
                        currentIndex: $currentIndex,
                        dragOffset: $dragOffset,
                        geometry: geometry,
                        onUpdate: { jot, content in
                            Task {
                                await db.updateJot(jot, content: content)
                            }
                        }
                    )
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !jots.isEmpty {
                AddButton(action: createNewJot)
                    .padding(24)
            }
        }
    }
    
    private func createNewJot() {
        Task {
            if let _ = await db.createJot() {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentIndex = 0
                }
            }
        }
    }
}
