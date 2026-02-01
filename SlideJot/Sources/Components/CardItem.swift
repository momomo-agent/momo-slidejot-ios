import SwiftUI

struct CardItem: View {
    let jot: Jot
    let isCurrent: Bool
    let isCollapsed: Bool
    let onUpdate: (String) -> Void
    let onTap: () -> Void
    
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            
            if isEditing && !isCollapsed {
                editor
            } else {
                content
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.cardBackground)
                
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if isCollapsed {
                onTap()
            } else if !isEditing {
                startEditing()
            }
        }
    }
    
    private var header: some View {
        HStack {
            if jot.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            Spacer()
            Text(jot.updatedDate.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var content: some View {
        ScrollView {
            Text(jot.content.isEmpty ? "点击编辑..." : jot.content)
                .font(.body)
                .foregroundColor(jot.content.isEmpty ? .secondaryText : .primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
    }
    
    private var editor: some View {
        TextEditor(text: $editText)
            .focused($isFocused)
            .font(.body)
            .foregroundColor(.primaryText)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 16)
            .onChange(of: isFocused) { _, focused in
                if !focused { finishEditing() }
            }
    }
    
    private func startEditing() {
        editText = jot.content
        withAnimation(.none) {
            isEditing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isFocused = true
        }
    }
    
    private func finishEditing() {
        if editText != jot.content {
            onUpdate(editText)
        }
        isEditing = false
    }
}
