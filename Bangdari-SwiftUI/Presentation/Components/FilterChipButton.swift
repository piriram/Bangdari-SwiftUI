import SwiftUI

enum FilterChipStyle {
    case outlined
    case filledActive
}

struct FilterChipButton: View {
    let title: String
    let isActive: Bool
    var style: FilterChipStyle = .outlined
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.pretendardBody2)
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(backgroundColor)
                .overlay(
                    Capsule()
                        .stroke(strokeColor, lineWidth: 1.2)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch style {
        case .outlined:
            return isActive ? .brightWood : .gray75
        case .filledActive:
            return isActive ? .gray0 : .gray75
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .outlined:
            return .gray0
        case .filledActive:
            return isActive ? .brightWood : .gray0
        }
    }

    private var strokeColor: Color {
        switch style {
        case .outlined:
            return isActive ? .brightWood : .gray45
        case .filledActive:
            return isActive ? .brightWood : .gray45
        }
    }
}

