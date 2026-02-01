import SwiftUI

enum CardSizeMode: String {
    case compact, regular
    
    var heightRatio: CGFloat {
        switch self {
        case .compact: return 0.10
        case .regular: return 0.25
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var db: DatabaseManager
    @Namespace private var cardNamespace
    @State private var currentJotId: String? = nil
    @State private var isCollapsed = true
    @State private var pullOffset: CGFloat = 0
    @State private var showSettings = false
    @State private var keyboardVisible = false
    @State private var cardSizeMode: CardSizeMode = .regular
    @State private var scrolledJotId: String?
    
    private var jots: [Jot] {
        db.jots.filter { !$0.isTrashed }.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.appBackground.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { handleBackgroundTap() }
                
                if db.isLoading {
                    ProgressView()
                } else if jots.isEmpty {
                    emptyState
                } else {
                    cardContent(geo: geo)
                }
                
                if !keyboardVisible {
                    bottomButtons(geo: geo)
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardVisible = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) { keyboardVisible = false }
        }
    }
    
    private func handleBackgroundTap() {
        if keyboardVisible {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        } else if !isCollapsed {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                isCollapsed = true
            }
        }
    }
    
    private func cardContent(geo: GeometryProxy) -> some View {
        let expandedW = geo.size.width - 40
        let expandedH = geo.size.height * 0.7
        let collapsedW = geo.size.width - 60
        let collapsedH = geo.size.height * cardSizeMode.heightRatio
        
        return ZStack {
            // 列表始终存在
            List {
                ForEach(jots) { jot in
                    CardItem(
                        jot: jot,
                        isCurrent: jot.id == currentJotId,
                        isCollapsed: true,
                        onUpdate: { _ in },
                        onTap: {
                            currentJotId = jot.id
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isCollapsed = false
                            }
                        }
                    )
                    .frame(width: collapsedW, height: collapsedH)
                    .opacity(isCollapsed || jot.id != currentJotId ? 1 : 0)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 30, bottom: 8, trailing: 30))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await db.trashJot(jot) }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollPosition(id: $scrolledJotId)
            .simultaneousGesture(
                MagnifyGesture()
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3)) {
                            if value.magnification > 1.2 {
                                cardSizeMode = .regular
                            } else if value.magnification < 0.8 {
                                cardSizeMode = .compact
                            }
                        }
                    }
            )
            .allowsHitTesting(isCollapsed)
            
            // 展开的卡片覆盖层
            if let currentJot = jots.first(where: { $0.id == currentJotId }) {
                let pullProgress = min(pullOffset / 200, 1.0)
                let animProgress = isCollapsed ? 1.0 : pullProgress
                let currentW = expandedW - (expandedW - collapsedW) * animProgress
                let currentH = expandedH - (expandedH - collapsedH) * animProgress
                
                Group {
                    if !isCollapsed {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture { handleBackgroundTap() }
                            .gesture(
                                keyboardVisible ? nil :
                                DragGesture(minimumDistance: 5)
                                    .onChanged { value in
                                        if value.translation.height > 0 {
                                            pullOffset = value.translation.height
                                        }
                                    }
                                    .onEnded { value in
                                        if value.translation.height > 100 {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                                isCollapsed = true
                                                pullOffset = 0
                                            }
                                        } else {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                                pullOffset = 0
                                            }
                                        }
                                    }
                            )
                    }
                }
                
                CardItem(
                    jot: currentJot,
                    isCurrent: true,
                    isCollapsed: isCollapsed,
                    onUpdate: { text in Task { await db.updateJot(currentJot, content: text) } },
                    onTap: {}
                )
                .frame(width: currentW, height: currentH)
                .offset(y: pullOffset * 0.5)
                .opacity(isCollapsed ? 0 : 1)
                .allowsHitTesting(!isCollapsed)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cardBackground.opacity(0.5))
                    .frame(width: 100, height: 120)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -15, y: 10)
                
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cardBackground.opacity(0.7))
                    .frame(width: 100, height: 120)
                    .rotationEffect(.degrees(5))
                    .offset(x: 10, y: 5)
                
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cardBackground)
                    .frame(width: 100, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            }
            
            VStack(spacing: 8) {
                Text("Stay Draft.")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primaryText)
                Text("Stay Messy.")
                    .font(.title3)
                    .foregroundColor(.secondaryText)
            }
            
            Text("点击 + 开始你的第一张便签")
                .font(.subheadline)
                .foregroundColor(.secondaryText.opacity(0.7))
        }
    }
    
    private func bottomButtons(geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(.secondaryText)
                        .frame(width: 44, height: 44)
                }
                .padding(.leading, 24)
                
                Spacer()
                
                Button {
                    Task {
                        if let newJot = await db.createJot() {
                            currentJotId = newJot.id
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                isCollapsed = false
                            }
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.appBackground)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.primaryText))
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                .padding(.trailing, 24)
            }
            .padding(.bottom, 24)
        }
    }
}
