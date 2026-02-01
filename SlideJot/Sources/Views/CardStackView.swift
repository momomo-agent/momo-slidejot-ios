import SwiftUI

struct CardStackView: View {
    let jots: [Jot]
    @Binding var currentIndex: Int
    @Binding var dragOffset: CGFloat
    let geometry: GeometryProxy
    let onUpdate: (Jot, String) -> Void
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
            
            ForEach(Array(jots.enumerated()), id: \.element.id) { index, jot in
                if abs(index - currentIndex) <= 2 {
                    JotCardView(jot: jot) { newContent in
                        onUpdate(jot, newContent)
                    }
                    .frame(width: geometry.size.width - 40)
                    .offset(x: offsetForIndex(index))
                    .scaleEffect(scaleForIndex(index))
                    .opacity(opacityForIndex(index))
                    .zIndex(Double(jots.count - abs(index - currentIndex)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    handleDragEnd(value: value, screenWidth: geometry.size.width)
                }
        )
    }
    
    private func offsetForIndex(_ index: Int) -> CGFloat {
        let baseOffset = CGFloat(index - currentIndex) * (geometry.size.width - 20)
        return baseOffset + dragOffset
    }
    
    private func scaleForIndex(_ index: Int) -> CGFloat {
        let distance = abs(index - currentIndex)
        if distance == 0 {
            return 1.0 - abs(dragOffset) / 2000
        }
        return max(0.9, 1.0 - CGFloat(distance) * 0.05)
    }
    
    private func opacityForIndex(_ index: Int) -> Double {
        let distance = abs(index - currentIndex)
        return max(0.5, 1.0 - Double(distance) * 0.3)
    }
    
    private func handleDragEnd(value: DragGesture.Value, screenWidth: CGFloat) {
        let threshold = screenWidth * 0.15  // 降低阈值，更灵敏
        let velocity = value.predictedEndTranslation.width - value.translation.width
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if value.translation.width < -threshold || velocity < -500 {
                if currentIndex < jots.count - 1 {
                    currentIndex += 1
                }
            } else if value.translation.width > threshold || velocity > 500 {
                if currentIndex > 0 {
                    currentIndex -= 1
                }
            }
            dragOffset = 0
        }
    }
}
