import SwiftUI

// MARK: - Estate Category

enum EstateCategory: String, CaseIterable, Identifiable {
    case oneRoom = "원룸"
    case officetel = "오피스텔"
    case apartment = "아파트"
    case villa = "빌라"
    case commercial = "상가"

    var id: String { rawValue }

    var imageName: String {
        switch self {
        case .oneRoom: return "CategoryOneRoom"
        case .officetel: return "CategoryOfficetel"
        case .apartment: return "CategoryApartment"
        case .villa: return "CategoryVilla"
        case .commercial: return "CategoryCommercial"
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
                    Rectangle()
                        .fill(Color.gray30)
                        .cornerRadius(16)
                        .frame(width: 50, height: 50)

                    Image(category.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }

                Text(category.rawValue)
                    .font(.pretendard(.body3,.medium))
                    .foregroundColor(isSelected ? .deepCoast : .gray75)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Selector

struct CategorySelector: View {
    @Binding var selectedCategory: EstateCategory?
    var onSelect: ((EstateCategory) -> Void)?

    var body: some View {
        HStack(spacing: 17) {
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack(spacing: 40) {
        CategorySelector(selectedCategory: .constant(nil))
        CategorySelector(selectedCategory: .constant(.oneRoom))
    }
}
