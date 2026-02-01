import SwiftUI

struct EmptyStateView: View {
    let onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.secondaryText)
            
            VStack(spacing: 8) {
                Text("Stay Draft. Stay Messy.")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text("随手记，不用整理")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            
            Button(action: onCreateNew) {
                Label("新建笔记", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accent)
                    .clipShape(Capsule())
            }
        }
    }
}
