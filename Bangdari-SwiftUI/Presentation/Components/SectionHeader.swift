import SwiftUI

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.pretendard(.body2,.bold))
                .foregroundColor(.gray90)

            Spacer()

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.pretendard(.caption1, .semiBold))
                        .foregroundColor(.deepCoast)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeader(title: "최근검색 매물")
        SectionHeader(title: "최근검색 매물", actionTitle: "View All") {}
        SectionHeader(title: "HOT 매물", actionTitle: "더보기") {}
    }
}
