import SwiftUI

// MARK: - Skeleton Modifier

struct SkeletonModifier: ViewModifier {
    @State private var shimmerOffset: CGFloat = -300

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: shimmerOffset)
            )
            .onAppear {
                shimmerOffset = 300
            }
    }
}

// MARK: - View Extension

extension View {
    func skeleton() -> some View {
        modifier(SkeletonModifier())
    }
}
