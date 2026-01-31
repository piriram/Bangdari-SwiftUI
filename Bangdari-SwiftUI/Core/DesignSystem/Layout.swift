import SwiftUI

// MARK: - Design System Layout

enum DesignSystem {
    enum Layout {
        // MARK: - 비율 상수

        /// 히어로 배너 높이 비율 (기준: iPhone 15 Pro 844 기준 355)
        static let heroBannerHeightRatio: CGFloat = 360 / 844

        // MARK: - 계산된 높이

        /// 히어로 배너 높이 (화면 높이의 42.1%)
        static var heroBannerHeight: CGFloat {
            UIScreen.main.bounds.height * heroBannerHeightRatio
        }

        // MARK: - 코너 라디우스 상수

        /// 검색바 기준 너비 (비율 계산용)
        static let searchBarBaseWidth: CGFloat = 350

        /// 검색바 기준 코너 라디우스
        static let searchBarBaseRadius: CGFloat = 20

        // MARK: - 아이콘 크기

        enum IconSize {
            static let xsmall: CGFloat = 14
            static let small: CGFloat = 16
            static let medium: CGFloat = 20
            static let large: CGFloat = 24
        }
    }
}

// MARK: - Environment Values (런타임 오버라이드)

private struct HeroBannerHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = DesignSystem.Layout.heroBannerHeight
}

extension EnvironmentValues {
    /// 히어로 배너 높이 (Environment로 오버라이드 가능)
    var heroBannerHeight: CGFloat {
        get { self[HeroBannerHeightKey.self] }
        set { self[HeroBannerHeightKey.self] = newValue }
    }
}

// MARK: - View Extensions (편의 기능)

extension View {
    /// 커스텀 히어로 배너 높이 설정 (Preview/테스트용)
    func heroBannerHeight(_ height: CGFloat) -> some View {
        environment(\.heroBannerHeight, height)
    }
}
