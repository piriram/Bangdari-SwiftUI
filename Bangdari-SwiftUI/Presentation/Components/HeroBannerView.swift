import Kingfisher
import SwiftUI

// MARK: - Hero Banner View (Estate 기반)

struct HeroBannerView: View {
    let estates: [EstateSummaryResponse]
    let height: CGFloat
    var onTap: ((EstateSummaryResponse) -> Void)?

    @State private var currentPage = 0
    @State private var locationCache: [String: String] = [:] // estate_id: 주소

    var body: some View {
        ZStack {
                // 1️⃣ 배경 이미지 캐러셀
                TabView(selection: $currentPage) {
                    ForEach(Array(estates.enumerated()), id: \.element.estate_id) { index, estate in
                        estateImage(estate: estate)
                            .tag(index)
                            .onTapGesture {
                                onTap?(estate)
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 2️⃣ 하단 딤 (Dim)
                Image("Dim View")
                    .resizable()
                    .scaledToFill()
                    .allowsHitTesting(false)

                // 3️⃣ 배너 텍스트 (좌측 하단)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                            .frame(width:20)
                        estateTextOverlay
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 36)
                }
                .allowsHitTesting(false)

                // 4️⃣ 페이지 인디케이터 (하단 중앙)
                VStack {
                    Spacer()
                    pageIndicator
                        .padding(.bottom, 16)
                }
                .allowsHitTesting(false)
        }
        .frame(height: height)
    }

    // MARK: - 배경 이미지

    private func estateImage(estate: EstateSummaryResponse) -> some View {
        GeometryReader { geo in
            KFImage.auth(url: imageURL(for: estate))
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
    }

    // MARK: - 매물 텍스트

    private var estateTextOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            if currentPage < estates.count {
                let estate = estates[currentPage]

                // 위치 정보
                HStack(spacing: 4) {
                    DSIconView(.location, size: 16, renderingMode: .template)
                        .foregroundColor(.gray15)

                    if let location = locationCache[estate.estate_id] {
                        Text(location)
                            .font(.pretendard(.caption2,.medium))
                            .foregroundColor(.gray15)
                    } else {
                        // 로딩 중
                        Text("위치 로딩중...")
                            .font(.pretendard(.caption2,.medium))
                            .foregroundColor(.gray15)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.gray60.opacity(0.25))
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12){
                    // 메인 타이틀
                    Text(estate.title)
                        .font(.yeongdeokTitle1())
                        .foregroundColor(.gray15)
                        .lineLimit(2)
                        .padding(.bottom, 2)

                    // 설명
                    Text(estate.introduction)
                        .font(.yeongdeokCaption1())
                        .foregroundColor(.introductionGray)
                        .lineLimit(1)
                }
            }
        }
        .task(id: currentPage) {
            await loadLocationIfNeeded()
        }
    }

    // MARK: - 페이지 인디케이터

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<estates.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.gray0 : Color.gray60.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Helpers

    /// 현재 페이지의 위치 정보를 로드 (캐시 확인 후 필요 시 역지오코딩)
    private func loadLocationIfNeeded() async {
        guard currentPage < estates.count else { return }

        let estate = estates[currentPage]

        // 이미 캐시에 있으면 스킵
        if locationCache[estate.estate_id] != nil {
            return
        }

        // 역지오코딩
        let location = await LocationService.shared.reverseGeocode(
            latitude: estate.geolocation.latitude,
            longitude: estate.geolocation.longitude,
            format: .short  // "서울 반포동"
        )

        // 캐시에 저장
        locationCache[estate.estate_id] = location ?? estate.category
    }

    private func imageURL(for estate: EstateSummaryResponse) -> URL? {
        guard let first = estate.files.first, !first.isEmpty else { return nil }

        // Mock 모드: 로컬 파일 경로를 file:// URL로 변환
        if AppEnvironment.current == .mock {
            return URL(fileURLWithPath: first)
        }

        // Live 모드: 서버 URL
        return URL(string: APIConfig.baseURL + "/" + first)
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
                            DSIconView(.location, size: 16, renderingMode: .template)
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

        // Mock 모드: 로컬 파일 경로를 file:// URL로 변환
        if AppEnvironment.current == .mock {
            return URL(fileURLWithPath: first)
        }

        // Live 모드: 서버 URL
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
