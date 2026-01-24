import Kingfisher
import SwiftUI

// MARK: - Estate Detail View

struct EstateDetailView: View {
    @StateObject private var intent: EstateDetailIntent
    @Environment(\.dismiss) private var dismiss
    @State private var currentImageIndex = 0

    private let imageHeight: CGFloat = 280

    init(estateId: String) {
        _intent = StateObject(wrappedValue: EstateDetailIntent(estateId: estateId))
    }

    var body: some View {
        Group {
            if let estate = intent.state.estate {
                detailContent(estate)
            } else if let error = intent.state.errorMessage {
                errorView(error)
            } else {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await intent.loadDetail()
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ estate: EstateDetailResponse) -> some View {
        ZStack(alignment: .top) {
            // 배경
            Color.gray15.ignoresSafeArea()

            // 1️⃣ 상단 히어로 이미지
            imageCarousel(estate.files)
                .ignoresSafeArea(edges: .top)

            // 2️⃣ 스크롤 콘텐츠
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 이미지 영역만큼 상단 여백
                    Spacer()
                        .frame(height: imageHeight)

                    // 실시간 상태 정보
                    statusSection(estate)

                    // 매물 핵심 정보
                    priceInfoSection(estate)

                    // 옵션 정보 카드
                    optionGridSection(estate.options)

                    // 상세 설명
                    descriptionSection(estate)

                    // 유사한 매물
                    if !intent.state.similarEstates.isEmpty {
                        similarEstatesSection
                    }

                    // 중개사 정보
                    agentInfoSection(estate.creator)

                    // 하단 여백 (CTA 영역)
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
            }

            // 상단 네비게이션 오버레이
            navigationOverlay
        }
        .safeAreaInset(edge: .bottom) {
            // 3️⃣ 하단 고정 CTA
            bottomCTABar(estate)
        }
    }

    // MARK: - Navigation Overlay

    private var navigationOverlay: some View {
        HStack {
            Button { dismiss() } label: {
                Image(dsIcon: .chevron)
                    .renderingMode(.template)
                    .foregroundColor(.gray0)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, topSafeAreaInset + 8)
    }

    // MARK: - 1. Image Carousel (히어로 영역)

    private func imageCarousel(_ files: [String]) -> some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(files.enumerated()), id: \.offset) { index, file in
                    KFImage.auth(url: URL(string: APIConfig.baseURL + "/" + file))
                        .resizable()
                        .scaledToFill()
                        .frame(height: imageHeight)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: imageHeight)

            // 하단 그라데이션
            LinearGradient(
                colors: [.black.opacity(0.3), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
            .frame(height: imageHeight)
            .allowsHitTesting(false)

            // 이미지 인덱스 (우측 하단)
            Text("\(currentImageIndex + 1)/\(max(files.count, 1))")
                .font(.pretendard(.caption2, .medium))
                .foregroundColor(.gray0)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
                .padding(16)
        }
    }

    // MARK: - 2-1. 실시간 상태 정보

    private func statusSection(_ estate: EstateDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // n명이 함께 보는 중
            Text("34명이 함께 보는 중")
                .font(.pretendard(.caption1))
                .foregroundColor(.gray75)

            // 태그
            HStack(spacing: 8) {
                if estate.is_safe_estate {
                    HStack(spacing: 4) {
                        Image(dsIcon: .safety)
                            .renderingMode(.template)
                            .frame(width: 14, height: 14)
                        Text("구매자 안심매물")
                            .font(.pretendard(.caption2, .medium))
                    }
                    .foregroundColor(.deepCoast)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.brightCoast.opacity(0.15))
                    .clipShape(Capsule())
                }

                if estate.is_reserved {
                    Text("예약중")
                        .font(.pretendard(.caption2, .medium))
                        .foregroundColor(.deepWood)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.brightCream)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(12)
    }

    // MARK: - 2-2. 매물 핵심 정보

    private func priceInfoSection(_ estate: EstateDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 주소
            Text("서울 영등포구 선유로9길 30") // TODO: 실제 주소
                .font(.pretendard(.caption1))
                .foregroundColor(.gray75)

            // 가격 (가장 강조)
            if estate.monthly_rent > 0 {
                Text("월세 \(formatPrice(estate.deposit)) / \(estate.monthly_rent)")
                    .font(.pretendard(.title1, .bold))
                    .foregroundColor(.gray90)
            } else {
                Text("전세 \(formatPrice(estate.deposit))")
                    .font(.pretendard(.title1, .bold))
                    .foregroundColor(.gray90)
            }

            // 관리비 / 면적
            Text("관리비 별도 · \(String(format: "%.1f", estate.area))m² · \(estate.floors)")
                .font(.pretendard(.caption1))
                .foregroundColor(.gray75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(12)
    }

    // MARK: - 2-3. 옵션 정보 카드

    private func optionGridSection(_ options: EstateOptions) -> some View {
        let allOptions = [
            ("냉장고", "OptionRefrigerator", options.option1),
            ("세탁기", "OptionWashingMachine", options.option2),
            ("에어컨", "OptionAirConditioner", options.option3),
            ("옷장", "OptionCloset", options.option4),
            ("신발장", "OptionShoeCabinet", options.option5),
            ("전자레인지", "OptionMicrowave", options.option6),
            ("싱크대", "OptionSink", options.option7),
            ("TV", "OptionTelevision", options.option8)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            Text("옵션 정보")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(allOptions, id: \.0) { name, icon, enabled in
                    VStack(spacing: 6) {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .opacity(enabled ? 1.0 : 0.25)

                        Text(name)
                            .font(.pretendard(.caption2))
                            .foregroundColor(enabled ? .gray90 : .gray45)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(12)
    }

    // MARK: - 2-4. 상세 설명

    private func descriptionSection(_ estate: EstateDetailResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 설명")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)

            Text(estate.title) // TODO: 실제 description 필드
                .font(.pretendard(.body3))
                .foregroundColor(.gray75)
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(12)
    }

    // MARK: - 2-5. 유사한 매물

    private var similarEstatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("유사한 매물")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(intent.state.similarEstates, id: \.estate_id) { estate in
                        NavigationLink(destination: EstateDetailView(estateId: estate.estate_id)) {
                            similarEstateCard(estate)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.leading, 16)
        .background(Color.gray0)
        .cornerRadius(12)
    }

    private func similarEstateCard(_ estate: EstateSummaryResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            KFImage.auth(url: similarEstateImageURL(estate))
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width * 0.55, height: 120)
                .background(Color.gray15)
                .clipped()
                .cornerRadius(8)

            Text(estate.category)
                .font(.pretendard(.caption2))
                .foregroundColor(.gray75)

            Text(estate.title)
                .font(.pretendard(.body3))
                .foregroundColor(.gray90)
                .lineLimit(1)

            Text(similarPriceText(estate))
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)
        }
        .frame(width: UIScreen.main.bounds.width * 0.55)
    }

    // MARK: - 2-6. 중개사 정보

    private func agentInfoSection(_ creator: UserInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("중개사 정보")
                .font(.pretendard(.body2, .semiBold))
                .foregroundColor(.gray90)

            HStack(spacing: 12) {
                // 프로필 이미지
                KFImage.auth(url: profileImageURL(creator.profileImage))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .background(Color.gray30)
                    .clipShape(Circle())

                // 이름
                VStack(alignment: .leading, spacing: 2) {
                    Text(creator.nick)
                        .font(.pretendard(.body2, .semiBold))
                        .foregroundColor(.gray90)

                    Text("공인중개사")
                        .font(.pretendard(.caption1))
                        .foregroundColor(.gray75)
                }

                Spacer()
            }

            // 전화 / 채팅 버튼
            HStack(spacing: 12) {
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(contactIcon: .call)
                            .renderingMode(.template)
                            .frame(width: 16, height: 16)
                        Text("전화")
                            .font(.pretendard(.body3))
                    }
                    .foregroundColor(.gray90)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.gray15)
                    .cornerRadius(8)
                }

                Button {} label: {
                    HStack(spacing: 6) {
                        Image(contactIcon: .chat)
                            .renderingMode(.template)
                            .frame(width: 16, height: 16)
                        Text("채팅")
                            .font(.pretendard(.body3))
                    }
                    .foregroundColor(.gray90)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.gray15)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(12)
    }

    // MARK: - 3. 하단 고정 CTA

    private func bottomCTABar(_ estate: EstateDetailResponse) -> some View {
        HStack(spacing: 12) {
            // 찜 버튼
            Button {
                Task { await intent.toggleLike() }
            } label: {
                Image(dsIcon: intent.state.isLiked ? .likeFill : .likeEmpty)
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(intent.state.isLiked ? .red : .gray75)
                    .frame(width: 52, height: 52)
                    .background(Color.gray15)
                    .cornerRadius(12)
            }
            .disabled(intent.state.isLikeLoading)

            // CTA 버튼
            Button {
                // TODO: 예약 플로우
            } label: {
                Text(estate.is_reserved ? "예약완료" : "예약하기")
                    .font(.pretendard(.body1, .bold))
                    .foregroundColor(estate.is_reserved ? .gray60 : .gray0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(estate.is_reserved ? Color.gray30 : Color.deepCream)
                    .cornerRadius(12)
            }
            .disabled(estate.is_reserved)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            Color.gray0
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(message)
                .font(.pretendard(.body2))
                .foregroundColor(.gray60)

            Button("다시 시도") {
                Task { await intent.loadDetail() }
            }
            .font(.pretendard(.body2, .semiBold))
            .foregroundColor(.deepCoast)
        }
    }

    // MARK: - Helpers

    private var topSafeAreaInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    private func formatPrice(_ price: Int) -> String {
        if price >= 10000 {
            let billion = price / 10000
            let remainder = price % 10000
            return remainder == 0 ? "\(billion)억" : "\(billion)억 \(remainder)"
        }
        return "\(price)"
    }

    private func profileImageURL(_ path: String?) -> URL? {
        guard let path else { return nil }
        return URL(string: APIConfig.baseURL + "/" + path)
    }

    private func similarEstateImageURL(_ estate: EstateSummaryResponse) -> URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: APIConfig.baseURL + "/" + first)
    }

    private func similarPriceText(_ estate: EstateSummaryResponse) -> String {
        if estate.monthly_rent > 0 {
            return "월세 \(estate.deposit)/\(estate.monthly_rent)"
        }
        return "전세 \(estate.deposit)"
    }
}

#Preview {
    NavigationStack {
        EstateDetailView(estateId: "test")
    }
}
