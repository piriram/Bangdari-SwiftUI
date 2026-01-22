import Kingfisher
import SwiftUI

// MARK: - Estate Card Small

struct EstateCardSmall: View {
    let estate: EstateSummaryResponse
    var isRecommended: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // 이미지
            KFImage.auth(url: imageURL)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 100, height: 100)
                .background(Color.gray15)
                .cornerRadius(8)
                .clipped()

            // 정보
            VStack(alignment: .leading, spacing: 6) {
                // 태그
                HStack(spacing: 4) {
                    if isRecommended {
                        Badge(text: "추천", style: .primary)
                    }
                    Badge(text: estate.category, style: .secondary)
                }

                // 가격
                Text(priceText)
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray90)
                    .lineLimit(1)

                // 제목
                Text(estate.title)
                    .font(.pretendardBody3)
                    .foregroundColor(.gray75)
                    .lineLimit(1)

                // 면적
                Text(areaText)
                    .font(.pretendardCaption1)
                    .foregroundColor(.gray60)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: 240, height: 124)
        .background(Color.gray0)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private var imageURL: URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: APIConfig.baseURL + "/" + first)
    }

    private var priceText: String {
        if estate.monthly_rent > 0 {
            return "월세 \(formatPrice(estate.deposit))/\(estate.monthly_rent)"
        } else {
            return "전세 \(formatPrice(estate.deposit))"
        }
    }

    private var areaText: String {
        let pyeong = estate.area / 3.3
        return String(format: "%.1f㎡ (%.0f평)", estate.area, pyeong)
    }

    private func formatPrice(_ price: Int) -> String {
        if price >= 10000 {
            let uk = price / 10000
            let remain = price % 10000
            if remain == 0 {
                return "\(uk)억"
            } else {
                return "\(uk)억 \(remain)"
            }
        }
        return "\(price)"
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            EstateCardSmall(
                estate: .preview,
                isRecommended: true
            )
            EstateCardSmall(
                estate: .preview,
                isRecommended: false
            )
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview Helper

extension EstateSummaryResponse {
    static var preview: EstateSummaryResponse {
        try! JSONDecoder().decode(
            EstateSummaryResponse.self,
            from: """
            {
                "estate_id": "preview_1",
                "category": "원룸",
                "title": "역삼역 도보 3분 신축 원룸",
                "deposit": 3000,
                "monthly_rent": 50,
                "area": 23.5,
                "geolocation": {"longitude": 127.0, "latitude": 37.5},
                "files": []
            }
            """.data(using: .utf8)!
        )
    }
}
