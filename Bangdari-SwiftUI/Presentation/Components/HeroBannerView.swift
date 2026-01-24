import Kingfisher
import SwiftUI

// MARK: - Hero Banner View

struct HeroBannerView: View {
    let banners: [Banner]
    var onTap: ((Banner) -> Void)?
    var onSearchTap: (() -> Void)?

    @State private var currentPage = 0

    private var topSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    var body: some View {
        ZStack {
                // 1️⃣ 배경 이미지 캐러셀
                TabView(selection: $currentPage) {
                    ForEach(Array(banners.enumerated()), id: \.element.banner_id) { index, banner in
                        bannerImage(banner: banner)
                            .tag(index)
                            .onTapGesture {
                                onTap?(banner)
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 2️⃣ 하단 그라데이션
                LinearGradient(
                    colors: [.black.opacity(0.45), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .allowsHitTesting(false)

                // 3️⃣ 검색바 (상단, Safe Area 아래)
                VStack {
                    heroSearchBar
                        .padding(.horizontal, 16)
                        .padding(.top, topSafeAreaInset + 8)
                    Spacer()
                        .allowsHitTesting(false)
                }

                // 4️⃣ 배너 텍스트 (좌측 하단)
                VStack {
                    Spacer()
                    bannerTextOverlay
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
                .allowsHitTesting(false)

                // 5️⃣ 페이지 인디케이터 (하단 중앙)
                VStack {
                    Spacer()
                    pageIndicator
                        .padding(.bottom, 12)
                }
                .allowsHitTesting(false)
        }
        .frame(height: 335)
    }

    // MARK: - 배경 이미지

    private func bannerImage(banner: Banner) -> some View {
        GeometryReader { geo in
            KFImage.auth(url: imageURL(for: banner))
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - 검색바

    private var heroSearchBar: some View {
        Button(action: { onSearchTap?() }) {
            HStack(spacing: 8) {
                Image(dsIcon: .search)
                    .renderingMode(.template)
                    .foregroundColor(.gray60)

                Text("검색어를 입력해주세요.")
                    .font(.pretendard(.body2))
                    .foregroundColor(.gray60)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.gray0)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 배너 텍스트

    private var bannerTextOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 위치 정보
            HStack(spacing: 4) {
                Image(dsIcon: .location)
                    .renderingMode(.template)
                    .foregroundColor(.gray0)
                Text("서울 반포동")
                    .font(.pretendard(.caption1))
                    .foregroundColor(.gray0)
            }

            // 메인 타이틀
            if currentPage < banners.count {
                Text(banners[currentPage].title)
                    .font(.pretendard(.title1, .bold))
                    .foregroundColor(.gray0)
                    .lineLimit(2)
            }

            // 서브 카피
            Text("외국 무료 사진 퍼온 것 같겠지만 한강입니다.")
                .font(.pretendard(.body3))
                .foregroundColor(.gray15)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 페이지 인디케이터

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<banners.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.gray0 : Color.gray60.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Helpers

    private func imageURL(for banner: Banner) -> URL? {
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
                KFImage.auth(url: imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    Spacer()

                    if !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(dsIcon: .location)
                                .renderingMode(.template)
                            Text(location)
                                .font(.pretendard(.caption1))
                        }
                        .foregroundColor(.gray0.opacity(0.9))
                    }

                    Text(estate.title)
                        .font(.pretendard(.title1, .bold))
                        .foregroundColor(.gray0)
                        .lineLimit(2)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.pretendard(.body3))
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
