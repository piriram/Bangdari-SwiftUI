import SwiftUI

// MARK: - Design System Icons

enum DesignSystemIcon: String {
    case fire = "IconFire"
    case focus = "IconFocus"
    case frame = "IconFrame"
    case likeEmpty = "IconLikeEmpty"
    case likeFill = "IconLikeFill"
    case list = "IconList"
    case location = "IconLocation"
    case map = "IconMap"
    case phone = "IconPhone"
    case safety = "IconSafety"
    case search = "IconSearch"
    case sort = "IconSort"
    case chevron = "IconChevron"
}

// MARK: - Legacy Image Extension (하위 호환성용)

extension Image {
    init(dsIcon: DesignSystemIcon) {
        self.init(dsIcon.rawValue)
    }
}

// MARK: - DS Icon View (권장)

/// 디자인 시스템 아이콘 뷰
/// - 자동으로 resizable, scaledToFit 적용
/// - 크기를 명시적으로 지정해야 함
struct DSIconView: View {
    let icon: DesignSystemIcon
    let size: CGFloat
    var renderingMode: Image.TemplateRenderingMode?

    init(_ icon: DesignSystemIcon, size: CGFloat, renderingMode: Image.TemplateRenderingMode? = nil) {
        self.icon = icon
        self.size = size
        self.renderingMode = renderingMode
    }

    var body: some View {
        Group {
            if let mode = renderingMode {
                Image(icon.rawValue)
                    .renderingMode(mode)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Image(icon.rawValue)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
    }
}
