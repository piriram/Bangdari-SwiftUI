import SwiftUI

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)

            Spacer()

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.pretendardCaption1) // TODO: semibold
                        .foregroundColor(.deepCoast)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeader(title: "최근검색 매물")
        SectionHeader(title: "최근검색 매물", actionTitle: "View All") {}
        SectionHeader(title: "HOT 매물", actionTitle: "더보기") {}
    }
}
