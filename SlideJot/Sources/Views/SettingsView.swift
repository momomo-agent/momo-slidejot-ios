import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var db: DatabaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: StorageMode = .local
    @State private var showRestartAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach([StorageMode.local, .macSync], id: \.self) { mode in
                        Button {
                            selectedMode = mode
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.title)
                                        .foregroundColor(.primaryText)
                                    Text(mode.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                                Spacer()
                                if selectedMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("存储位置")
                } footer: {
                    Text("切换后需要重启 App 生效")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if selectedMode != db.currentMode {
                            db.setStorageMode(selectedMode)
                            showRestartAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                selectedMode = db.currentMode
            }
            .alert("需要重启", isPresented: $showRestartAlert) {
                Button("好") { dismiss() }
            } message: {
                Text("存储位置已更改，请重启 App 生效")
            }
        }
    }
}
