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
