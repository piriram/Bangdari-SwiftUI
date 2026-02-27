import SwiftUI

// MARK: - Date Divider

struct DateDivider: View {
    let date: Date

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.gray30)
                .frame(height: 1)
                .layoutPriority(0) // lower than text so it shrinks first

            Text(formatDate(date))
                .font(.pretendard(.caption1, .medium))
                .foregroundColor(.gray60)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(Color.gray15)
                .cornerRadius(12)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false) // ensure full text width
                .layoutPriority(1) // text takes priority over side lines

            Rectangle()
                .fill(Color.gray30)
                .frame(height: 1)
                .layoutPriority(0) // lower than text so it shrinks first
        }
        .padding(.vertical, 16)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "오늘"
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 M월 d일 EEEE"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: date)
        }
    }
}
