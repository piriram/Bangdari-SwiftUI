import SwiftUI

// MARK: - Skeleton Modifier

struct SkeletonModifier: ViewModifier {
    @State private var shimmerOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .clear,
                                    .white.opacity(0.6),
                                    .white.opacity(0.8),
                                    .white.opacity(0.6),
                                    .clear,
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width)
                        .offset(x: shimmerOffset)
                }
            )
            .clipped()
            .onAppear {
                shimmerOffset = -UIScreen.main.bounds.width
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = UIScreen.main.bounds.width
                }
            }
    }
}

// MARK: - View Extension

extension View {
    func skeleton() -> some View {
        modifier(SkeletonModifier())
    }
}
