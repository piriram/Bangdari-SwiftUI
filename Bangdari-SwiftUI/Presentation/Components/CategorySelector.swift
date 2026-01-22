import SwiftUI

// MARK: - Estate Category

enum EstateCategory: String, CaseIterable, Identifiable {
    case oneRoom = "원룸"
    case officetel = "오피스텔"
    case apartment = "아파트"
    case villa = "빌라"
    case commercial = "상가"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .oneRoom: return "door.left.hand.closed"
        case .officetel: return "building"
        case .apartment: return "building.2"
        case .villa: return "house"
        case .commercial: return "storefront"
        }
    }
}

// MARK: - Category Item

struct CategoryItem: View {
    let category: EstateCategory
    var isSelected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.deepCoast.opacity(0.15) : Color.gray15)
                        .frame(width: 48, height: 48)

                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .deepCoast : .gray75)
                }

                Text(category.rawValue)
                    .font(.pretendardCaption1)
                    .foregroundColor(isSelected ? .deepCoast : .gray90)
            }
            .frame(minWidth: 60)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Selector

struct CategorySelector: View {
    @Binding var selectedCategory: EstateCategory?
    var onSelect: ((EstateCategory) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EstateCategory.allCases) { category in
                CategoryItem(
                    category: category,
                    isSelected: selectedCategory == category
                ) {
                    if selectedCategory == category {
                        selectedCategory = nil
                    } else {
                        selectedCategory = category
                    }
                    onSelect?(category)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 40) {
        CategorySelector(selectedCategory: .constant(nil))
        CategorySelector(selectedCategory: .constant(.oneRoom))
    }
}
