import SwiftUI
import Kingfisher

/// 맵에 표시되는 개별 매물 마커 (말풍선 스타일)
struct EstateMarkerView: View {
    let estate: EstateSummaryResponse
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 메인 콘텐츠 영역
            VStack(spacing: 6) {
                // 매물 이미지
                if let imageUrl = estate.files.first {
                    KFImage(URL(string: imageUrl))
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray30)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // 이미지 없을 때 플레이스홀더
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray30)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.gray45)
                        )
                }

                // 가격 정보
                VStack(spacing: 2) {
                    Text(formatPrice(deposit: estate.deposit, monthlyRent: estate.monthly_rent))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray0)
                        .lineLimit(1)

                    // 좋아요 수
                    HStack(spacing: 2) {
                        Text("❤️")
                            .font(.system(size: 10))
                        Text("\(estate.like_count)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray60)
                    }
                }
            }
            .padding(8)
            .background(Color.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: isSelected ? Color.deepCream.opacity(0.4) : Color.black.opacity(0.15),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )

            // 말풍선 꼬리 (하단 삼각형)
            Triangle()
                .fill(Color.gray0)
                .frame(width: 12, height: 6)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        }
        .frame(width: 75, height: 106) // 전체 크기 (콘텐츠 100 + 꼬리 6)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    /// 가격 포맷팅 (예: "3000/200")
    private func formatPrice(deposit: Int, monthlyRent: Int) -> String {
        let depositStr = deposit >= 10000 ? "\(deposit / 10000)억" : "\(deposit)"
        let rentStr = monthlyRent >= 100 ? "\(monthlyRent / 100)백" : "\(monthlyRent)"

        if monthlyRent > 0 {
            return "\(depositStr)/\(rentStr)"
        } else {
            return depositStr
        }
    }
}

/// 말풍선 꼬리를 위한 삼각형 Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
// Preview는 실제 앱에서 테스트하세요
