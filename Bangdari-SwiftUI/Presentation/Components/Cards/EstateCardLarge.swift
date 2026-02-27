import Kingfisher
import SwiftUI

// MARK: - Estate Card Large (HOT 매물용)

struct EstateCardLarge: View {
    let estate: EstateSummaryResponse
    var viewerCount: Int? = nil

    @State private var locationName: String?

    var body: some View {
        ZStack {
            // 배경 이미지
            KFImage.auth(url: imageURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 240, height: 83)
                .clipped()

            // 전체 그라데이션 (약하게)
            RadialGradient(
                colors: [
                    .black.opacity(0.55),
                    .black.opacity(0.0)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )

            // 좌상단 HOT 아이콘
            VStack {
                HStack {
                    DSIconView(.fire, size: 24, renderingMode: .template)
                        .foregroundColor(.white)

                    Spacer()
                }
                Spacer()
            }
            .padding(8)

            // 우상단 텍스트
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(estate.title)
                            .font(.yeongdeokCaption1())
                            .foregroundColor(.gray0)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)

                        Text(estate.formattedPrice())
                            .font(.pretendard(.body1, .bold))
                            .foregroundColor(.gray0)
                    }
                }
                Spacer()
            }
            .padding(10)

            // 좌하단 시청자 수
            if let count = viewerCount, count > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Text("\(count)명이 함께 보는 중")
                            .font(.pretendard(.caption2))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.gray60.opacity(0.5))
                            .cornerRadius(6)

                        Spacer()
                    }
                }
                .padding(10)
            }

            // 우하단 면적
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(estate.formattedArea(locationName: locationName))
                        .font(.pretendard(.caption2))
                        .foregroundColor(.gray45)
                }
            }
            .padding(10)
        }
        .frame(width: 240, height: 83)
        .cornerRadius(10)
        .clipped()
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
        HStack(spacing: 16) {
            EstateCardLarge(estate: .preview, viewerCount: 34)
                .frame(width: 240, height: 83)

            EstateCardLarge(estate: .preview)
                .frame(width: 240, height: 83)
        }
        .padding(.horizontal, 16)
    }
}
