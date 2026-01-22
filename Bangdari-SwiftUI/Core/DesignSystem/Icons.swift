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

extension Image {
    init(dsIcon: DesignSystemIcon) {
        self.init(dsIcon.rawValue)
    }
}
