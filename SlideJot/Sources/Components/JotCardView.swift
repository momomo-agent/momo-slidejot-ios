import SwiftUI

struct JotCardView: View {
    let jot: Jot
    let onUpdate: (String) -> Void
    
    @State private var isEditing = false
    @State private var editText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部工具栏
            HStack {
                if jot.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.accent)
                }
                Spacer()
                Text(jot.updatedDate.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 内容区域
            if isEditing {
                TextEditor(text: $editText)
                    .focused($isFocused)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 16)
            } else {
                ScrollView {
                    Text(jot.content.isEmpty ? "点击开始写..." : jot.content)
                        .font(.body)
                        .foregroundColor(jot.content.isEmpty ? .secondaryText : .primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            startEditing()
        }
        .onChange(of: isFocused) { _, newValue in
            if !newValue {
                finishEditing()
            }
        }
    }
    
    private func startEditing() {
        editText = jot.content
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isEditing = true
            isFocused = true
        }
    }
    
    private func finishEditing() {
        if editText != jot.content {
            onUpdate(editText)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isEditing = false
        }
    }
}
