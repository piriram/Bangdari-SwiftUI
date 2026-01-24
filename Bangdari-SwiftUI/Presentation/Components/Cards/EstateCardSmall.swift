import Kingfisher
import SwiftUI

// MARK: - Estate Card Small

struct EstateCardSmall: View {
    let estate: EstateSummaryResponse
    var isRecommended: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 썸네일
            KFImage.auth(url: imageURL)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // 텍스트 정보
            VStack(alignment: .leading, spacing: 4) {
                // 태그 + 카테고리
                HStack(spacing: 4) {
                    if isRecommended {
                        Text("추천")
                            .font(.pretendard(.caption2))
                            .foregroundColor(.deepWood)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brightCream)
                            .cornerRadius(6)
                    }

                    Text(estate.category)
                        .font(.pretendard(.caption1))
                        .foregroundColor(.gray75)
                }

                // 가격
                Text(priceText)
                    .font(.pretendard(.body2, .semiBold))
                    .foregroundColor(.gray90)
                    .lineLimit(1)

                // 면적
                Text(areaText)
                    .font(.pretendard(.caption1))
                    .foregroundColor(.gray75)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(height: 112)
        .background(Color.gray0)
        .cornerRadius(12)
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
        String(format: "%.1fm²", estate.area)
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
