import Kingfisher
import SwiftUI

// MARK: - Estate List Item

struct EstateListItem: View {
    let estate: EstateSummaryResponse
    @State private var address: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
            textStack
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(Color.gray0)
//        .cornerRadius(20)
        .task {
            // 역지오코딩으로 주소 가져오기
            GeolocationManager.shared.fetchFullAddress(
                latitude: estate.geolocation.latitude,
                longitude: estate.geolocation.longitude
            ) { fetchedAddress in
                address = fetchedAddress
            }
        }
    }

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            KFImage.auth(url: estate.mapImageURL)
                .placeholder {
                    Color.gray30
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 108)
                .clipped()
                .cornerRadius(8)

            if estate.is_safe_estate {
                DSIconView(.safety, size: 20, renderingMode: .original)
                    .offset(x: 8, y: 8)
            }
        }
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 1. [카테고리] + 제목
            HStack(spacing: 4) {
                tagBadge

                Text(estate.title)
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray90)
                    .lineLimit(1)
            }

            // 2. 가격
            Text(estate.formattedPrice())
                .font(.pretendardBody2)
                .foregroundColor(.gray75)

            // 3. 면적 · 층수
            Text("\(estate.formattedArea()) · \(estate.floors)층")
                .font(.pretendardCaption2)
                .foregroundColor(.gray60)

            // 4. 주소 (역지오코딩)
            if let address = address {
                Text(address)
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray60)
                    .lineLimit(1)
            }

            // 5. 소개/특징
            if !estate.introduction.isEmpty {
                Text("◇ \(estate.introduction)")
                    .font(.pretendardCaption2)
                    .foregroundColor(.gray60)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tagBadge: some View {
        Text(estate.category)
            .font(.pretendardCaption1)
            .foregroundColor(.gray0)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Color.deepWood)
            .clipShape(Capsule())
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1fkm", meters / 1000)
        }

        return "\(Int(meters))m"
    }
}
