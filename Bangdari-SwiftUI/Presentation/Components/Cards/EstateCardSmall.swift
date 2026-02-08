import Kingfisher
import SwiftUI

// MARK: - Estate Card Small

struct EstateCardSmall: View {
    let estate: EstateSummaryResponse
    var isRecommended: Bool = false

    @State private var locationName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 썸네일
            KFImage.auth(url: imageURL)
                .resizable()
                .scaledToFill()
                .frame(width: 69, height: 69)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // 텍스트 정보
            VStack(alignment: .leading, spacing: 8) {
                // 태그 + 카테고리
                HStack(spacing: 4) {
                    if isRecommended {
                        Text("추천")
                            .font(.pretendard(.caption3,.semiBold))
                            .foregroundColor(.brightWood)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.brightCream)
                            .cornerRadius(4)
                    }

                    Text(estate.category)
                        .font(.pretendard(.caption2,.semiBold))
                        .foregroundColor(.deepWood)
                }

                // 가격
                Text(estate.formattedPrice())
                    .font(.pretendard(.body3, .bold))
                    .foregroundColor(.gray90)
                    .lineLimit(1)

                // 면적
                Text(estate.formattedArea(locationName: locationName))
                    .font(.pretendard(.caption1))
                    .foregroundColor(.gray60)
                    .lineLimit(1)
            }
            .padding(.vertical,6)

        }
        .padding(12)
        .background(Color.gray0)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray30, lineWidth: 1)
        )
        .frame(minWidth:190)
        .onAppear {
            fetchLocationName()
        }
    }

    // MARK: - Helpers

    private var imageURL: URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: APIConfig.baseURL + "/" + first)
    }

    private func fetchLocationName() {
        GeolocationManager.shared.fetchLocationName(
            latitude: estate.geolocation.latitude,
            longitude: estate.geolocation.longitude
        ) { [self] name in
            locationName = name
        }
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
