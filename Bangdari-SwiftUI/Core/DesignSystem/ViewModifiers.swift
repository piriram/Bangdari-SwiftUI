import SwiftUI

// MARK: - Proportional Corner Radius

extension View {
    /// 비율 기반 코너 라디우스를 적용합니다.
    /// width가 변해도 시각적으로 동일한 둥근 정도를 유지합니다.
    ///
    /// - Parameters:
    ///   - baseWidth: 기준이 되는 width (예: 350)
    ///   - baseRadius: 기준 width에서의 코너 라디우스 (예: 20)
    ///
    /// - Example:
    /// ```swift
    /// Rectangle()
    ///     .proportionalCornerRadius(baseWidth: 350, baseRadius: 20)
    /// ```
    func proportionalCornerRadius(
        baseWidth: CGFloat,
        baseRadius: CGFloat
    ) -> some View {
        GeometryReader { geometry in
            let radius = geometry.size.width * (baseRadius / baseWidth)
            self
                .clipShape(RoundedRectangle(cornerRadius: radius))
        }
    }

    /// 비율 기반 코너 라디우스와 테두리를 함께 적용합니다.
    ///
    /// - Parameters:
    ///   - baseWidth: 기준이 되는 width (예: 350)
    ///   - baseRadius: 기준 width에서의 코너 라디우스 (예: 20)
    ///   - strokeColor: 테두리 색상
    ///   - lineWidth: 테두리 두께
    ///
    /// - Example:
    /// ```swift
    /// Rectangle()
    ///     .proportionalCornerRadius(
    ///         baseWidth: 350,
    ///         baseRadius: 20,
    ///         strokeColor: .gray,
    ///         lineWidth: 1
    ///     )
    /// ```
    func proportionalCornerRadius(
        baseWidth: CGFloat,
        baseRadius: CGFloat,
        strokeColor: Color,
        lineWidth: CGFloat = 1
    ) -> some View {
        GeometryReader { geometry in
            let radius = geometry.size.width * (baseRadius / baseWidth)
            self
                .clipShape(RoundedRectangle(cornerRadius: radius))
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(strokeColor, lineWidth: lineWidth)
                )
        }
    }
}

// MARK: - Design System Presets

extension View {
    /// 디자인 시스템 기본 코너 라디우스 (350 기준 20)
    func dsCornerRadius() -> some View {
        proportionalCornerRadius(baseWidth: 350, baseRadius: 20)
    }

    /// 디자인 시스템 기본 코너 라디우스 + 테두리 (350 기준 20)
    func dsCornerRadius(strokeColor: Color, lineWidth: CGFloat = 1) -> some View {
        proportionalCornerRadius(
            baseWidth: 350,
            baseRadius: 20,
            strokeColor: strokeColor,
            lineWidth: lineWidth
        )
    }
}

// MARK: - Asymmetric Corner Radius

extension View {
    /// 특정 모서리만 둥글게 처리
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Scroll Offset Tracking

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// 스크롤 오프셋을 측정합니다 (coordinate space "scroll" 필요)
    func measureScrollOffset(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: onChange)
    }
}
