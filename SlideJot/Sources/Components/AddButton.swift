import SwiftUI

struct AddButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accent)
                .clipShape(Circle())
                .shadow(color: Color.accent.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
}
