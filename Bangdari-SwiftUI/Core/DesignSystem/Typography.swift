import SwiftUI

// MARK: - Design System Typography

enum PretendardSize: CGFloat {
    case title1 = 20
    case body1 = 16
    case body2 = 14
    case body3 = 13
    case caption1 = 12
    case caption2 = 10
    case caption3 = 8
}

enum PretendardWeight: String {
    case regular = "Pretendard-Regular"
    case medium = "Pretendard-Medium"
    case semiBold = "Pretendard-SemiBold"
    case bold = "Pretendard-Bold"
}

extension Font {
    // MARK: - Pretendard

    /// 권장: .font(.pretendard(.body1, .semiBold))
    static func pretendard(_ size: PretendardSize, _ weight: PretendardWeight = .regular) -> Font {
        .custom(weight.rawValue, size: size.rawValue)
    }

    // MARK: - Legacy (기존 코드 호환용)

    static let pretendardTitle1 = Font.pretendard(.title1, .bold)
    static let pretendardBody1 = Font.pretendard(.body1)
    static let pretendardBody1Bold = Font.pretendard(.body1, .bold)
    static let pretendardBody2 = Font.pretendard(.body2)
    static let pretendardBody2Bold = Font.pretendard(.body2, .semiBold)
    static let pretendardBody3 = Font.pretendard(.body3)
    static let pretendardCaption1 = Font.pretendard(.caption1)
    static let pretendardCaption2 = Font.pretendard(.caption2, .medium)
    static let pretendardCaption3 = Font.pretendard(.caption3)

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
