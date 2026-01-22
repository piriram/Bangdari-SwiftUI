import Kingfisher
import SwiftUI

// MARK: - Hero Banner View

struct HeroBannerView: View {
    let banners: [Banner]
    var onTap: ((Banner) -> Void)?

    var body: some View {
        TabView {
            ForEach(banners, id: \.banner_id) { banner in
                BannerItemView(banner: banner)
                    .onTapGesture {
                        onTap?(banner)
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .aspectRatio(16 / 9, contentMode: .fit)
    }
}

// MARK: - Banner Item View

struct BannerItemView: View {
    let banner: Banner

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // 배경 이미지
                KFImage.auth(url: imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // 그라데이션 오버레이
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // 콘텐츠
                VStack(alignment: .leading, spacing: 8) {
                    // 제목
                    Text(banner.title)
                        .font(.pretendardTitle1)
                        .foregroundColor(.gray0)
                        .lineLimit(2)
                }
                .padding(20)
            }
        }
    }

    private var imageURL: URL? {
        guard !banner.image.isEmpty else { return nil }
        return URL(string: APIConfig.baseURL + "/" + banner.image)
    }
}

// MARK: - Featured Estate Banner (매물 기반 배너)

struct FeaturedEstateBanner: View {
    let estate: EstateSummaryResponse
    var location: String = ""
    var subtitle: String = ""

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // 배경 이미지
                KFImage.auth(url: imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                // 그라데이션 오버레이
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 콘텐츠
                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    // 위치 정보
                    if !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                            Text(location)
                                .font(.pretendardCaption1)
                        }
                        .foregroundColor(.gray0.opacity(0.9))
                    }

                    // 메인 타이틀
                    Text(estate.title)
                        .font(.pretendardTitle1)
                        .foregroundColor(.gray0)
                        .lineLimit(2)

                    // 서브 설명
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.pretendardBody3)
                            .foregroundColor(.gray15)
                            .lineLimit(1)
                    }
                }
                .padding(20)
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
    }

    private var imageURL: URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: APIConfig.baseURL + "/" + first)
    }
}

#Preview {
    VStack(spacing: 20) {
        FeaturedEstateBanner(
            estate: .preview,
            location: "서울 반포동",
            subtitle: "역세권 신축 아파트"
        )
        .frame(height: 200)
    }
    .padding()
}
