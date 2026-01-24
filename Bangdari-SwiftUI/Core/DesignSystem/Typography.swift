import SwiftUI

// MARK: - Design System Typography

extension Font {
    // MARK: - Pretendard

    static let pretendardTitle1 = Font.custom("Pretendard-Bold", size: 20)
    static let pretendardBody1 = Font.custom("Pretendard-Regular", size: 16)
    static let pretendardBody1Bold = Font.custom("Pretendard-Bold", size: 16)
    static let pretendardBody2 = Font.custom("Pretendard-Regular", size: 14)
    static let pretendardBody2Bold = Font.custom("Pretendard-SemiBold", size: 14)
    static let pretendardBody3 = Font.custom("Pretendard-Regular", size: 13)
    static let pretendardCaption1 = Font.custom("Pretendard-Regular", size: 12)
    static let pretendardCaption2 = Font.custom("Pretendard-Medium", size: 10)
    static let pretendardCaption3 = Font.custom("Pretendard-Regular", size: 8)

    // MARK: - Yeongdeok Haeparang (커스텀 폰트 등록 시)

    static func yeongdeokTitle1() -> Font {
        .custom("Yeongdeok-Haeparang", size: 20)
    }

    static func yeongdeokCaption1() -> Font {
        .custom("Yeongdeok-Haeparang", size: 12)
    }
}

// MARK: - Text Style Modifier

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.color)
    }
}

enum TextStyle {
    case title1
    case body1
    case body1Bold
    case body2
    case body2Bold
    case body3
    case caption1
    case caption2
    case caption3

    var font: Font {
        switch self {
        case .title1: return .pretendardTitle1
        case .body1: return .pretendardBody1
        case .body1Bold: return .pretendardBody1Bold
        case .body2: return .pretendardBody2
        case .body2Bold: return .pretendardBody2Bold
        case .body3: return .pretendardBody3
        case .caption1: return .pretendardCaption1
        case .caption2: return .pretendardCaption2
        case .caption3: return .pretendardCaption3
        }
    }

    var color: Color {
        switch self {
        case .title1, .body1, .body1Bold, .body2Bold:
            return .gray90
        case .body2, .body3:
            return .gray75
        case .caption1, .caption2, .caption3:
            return .gray60
        }
    }
}
