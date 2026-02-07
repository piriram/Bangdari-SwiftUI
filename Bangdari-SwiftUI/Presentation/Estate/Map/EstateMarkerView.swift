import Kingfisher
import SwiftUI

/// 맵에 표시되는 개별 매물 마커 (말풍선 스타일)
struct EstateMarkerView: View {
    let estate: EstateSummaryResponse
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                if let imageURL = estate.mapImageURL {
                    KFImage.auth(url: imageURL)
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray30)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray30)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.gray45)
                        )
                }

                VStack(spacing: 2) {
                    Text(estate.mapMarkerPriceText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray0)
                        .lineLimit(1)

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
        .frame(width: 75, height: 106)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
