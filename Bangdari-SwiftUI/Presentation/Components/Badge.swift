import SwiftUI

// MARK: - Badge Style

enum BadgeStyle {
    case primary    // DeepCoast
    case secondary  // BrightCoast
    case accent     // DeepWood
    case neutral    // Gray

    var backgroundColor: Color {
        switch self {
        case .primary: return .deepCoast
        case .secondary: return .brightCoast
        case .accent: return .deepWood
        case .neutral: return .gray45
        }
    }

    var textColor: Color {
        switch self {
        case .primary, .accent: return .gray0
        case .secondary: return .deepCoast
        case .neutral: return .gray90
        }
    }
}

// MARK: - Badge

struct Badge: View {
    let text: String
    var style: BadgeStyle = .primary

    var body: some View {
        Text(text)
            .font(.pretendardCaption2)
            .foregroundColor(style.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(style.backgroundColor)
            .cornerRadius(4)
    }
}

#Preview {
    HStack(spacing: 8) {
        Badge(text: "추천", style: .primary)
        Badge(text: "원룸", style: .secondary)
        Badge(text: "HOT", style: .accent)
        Badge(text: "빌라", style: .neutral)
    }
}
