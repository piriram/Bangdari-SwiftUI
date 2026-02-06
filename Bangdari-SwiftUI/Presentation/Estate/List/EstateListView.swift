import CoreLocation
import Kingfisher
import SwiftUI

// MARK: - Estate List View

struct EstateListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var intent = EstateListIntent()

    let mode: ListMode

    @State private var selectedEstateIdForDetail: String?
    @State private var activeFilter: FilterType?
    @State private var displayEstates: [EstateSummaryResponse] = []
    @State private var bannerInterval: Int = 6  // 기본값
    @State private var screenHeight: CGFloat = UIScreen.main.bounds.height

    enum ListMode {
        case map(coordinate: CLLocationCoordinate2D, estates: [EstateSummaryResponse], locationText: String)
        case liked
        case todayEstates(estates: [EstateSummaryResponse])
        case hotEstates(estates: [EstateSummaryResponse])
    }

    enum FilterType {
        case area, deposit, monthlyRent, immediate
    }

    var body: some View {
        ZStack {
            // Z1: Background
            Color.gray15.ignoresSafeArea()

            VStack(spacing: 0) {
                // Z2: Navigation Bar (System UI)
                navigationBar

                // Filter Chip Row (only for map mode)
                if case .map = mode {
                    filterChipRow
                        .padding(.top, 12)
                }

                // Z3: Scrollable Content Flow
                if intent.state.isLoading && displayEstates.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayEstates.isEmpty {
                    emptyView
                } else {
                    estateListContent
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedEstateIdForDetail) { estateId in
            EstateDetailView(estateId: estateId)
        }
        .task {
            bannerInterval = calculateBannerInterval()
            await loadInitialData()
        }
        .refreshable {
            await refresh()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        CustomNavigationBar(onBack: { dismiss() }) {
            // Center: Location + Text
            HStack(spacing: 6) {
                Image(dsIcon: .location)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.deepWood)

                Text(locationText)
                    .font(.pretendardBody1Bold)
                    .foregroundColor(.gray90)
            }
        } trailing: {
            // Trailing: Map Icon (liked mode only)
            if case .liked = mode {
                Button {
                    // TODO: Navigate to map
                } label: {
                    Image(dsIcon: .map)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray90)
                }
            }
        }
    }

    private var locationText: String {
        switch mode {
        case .map(_, _, let text):
            return text
        case .liked:
            return "좋아요한 매물"
        case .todayEstates:
            return "최근검색 매물"
        case .hotEstates:
            return "HOT 매물"
        }
    }

    // MARK: - Filter Chip Row

    private var filterChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip("면적 순", isActive: activeFilter == .area) {
                    toggleFilter(.area)
                }

                filterChip("보증금 순", isActive: activeFilter == .deposit) {
                    toggleFilter(.deposit)
                }

                filterChip("월세 순", isActive: activeFilter == .monthlyRent) {
                    toggleFilter(.monthlyRent)
                }

                filterChip("신축 순", isActive: activeFilter == .immediate) {
                    toggleFilter(.immediate)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 48)
    }

    private func filterChip(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendardBody3)
                .foregroundColor(isActive ? .deepCoast : .gray75)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.gray0)
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.deepCoast : Color.gray45, lineWidth: 1)
                )
        }
    }

    private func toggleFilter(_ filter: FilterType) {
        if activeFilter == filter {
            activeFilter = nil
        } else {
            activeFilter = filter
        }
        // TODO: MapView의 필터 상태와 공유 필요
        // TODO: 실제 필터 로직 구현 (면적순, 보증금순, 월세순, 신축순)
        updateDisplayEstates()
    }

    // MARK: - Estate List Content

    private var estateListContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(displayEstates.indices, id: \.self) { index in
                    estateRow(at: index)
                }

                // Load more indicator (liked mode only)
                if case .liked = mode, intent.state.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private func estateRow(at index: Int) -> some View {
        let estate = displayEstates[index]

        Button {
            selectedEstateIdForDetail = estate.estate_id
        } label: {
            EstateListItem(estate: estate)
        }
        .buttonStyle(.plain)

        // Dynamic interval banners (all modes)
        // 동적 간격으로 배너 표시 (순환 로직)
        if index < displayEstates.count - 1,
           !intent.state.banners.isEmpty,
           (index + 1) % bannerInterval == 0 {
            let bannerIndex = ((index + 1) / bannerInterval) % intent.state.banners.count
            let banner = intent.state.banners[bannerIndex]

            InlinePromoItem(banner: banner) { url in
                // TODO: BannerWebView 네비게이션 구현
                print("🔗 Banner clicked: \(url)")
            }
            .onAppear {
                print("🔄 [BANNER-CYCLE] Estate #\(index) 뒤에 배너 표시")
                print("  - Total Banners: \(intent.state.banners.count)")
                print("  - Selected Index: \(bannerIndex)")
                print("  - Banner Title: \(banner.title)")
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "house")
                .font(.system(size: 48))
                .foregroundColor(.gray60)

            Text(emptyMessage)
                .font(.pretendardBody2)
                .foregroundColor(.gray60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessage: String {
        switch mode {
        case .map:
            return "이 지역에 매물이 없습니다"
        case .liked:
            return "좋아요한 매물이 없습니다"
        case .todayEstates:
            return "최근검색 매물이 없습니다"
        case .hotEstates:
            return "HOT 매물이 없습니다"
        }
    }

    // MARK: - Helpers

    private func loadInitialData() async {
        switch mode {
        case .map(_, let estates, _):
            displayEstates = estates
        case .liked:
            await intent.loadMyLikedEstates()
            displayEstates = intent.state.estates
        case .todayEstates(let estates):
            displayEstates = estates
            await intent.loadBanners()  // 배너 로드 추가
        case .hotEstates(let estates):
            displayEstates = estates
            await intent.loadBanners()  // 배너 로드 추가
        }
    }

    private func refresh() async {
        switch mode {
        case .map(let coordinate, _, _):
            await intent.loadEstates(at: coordinate)
            displayEstates = intent.state.estates
        case .liked:
            await intent.loadMyLikedEstates()
            displayEstates = intent.state.estates
        case .todayEstates(let estates):
            displayEstates = estates
        case .hotEstates(let estates):
            displayEstates = estates
        }
    }

    private func updateDisplayEstates() {
        switch mode {
        case .map(_, let estates, _):
            displayEstates = estates // TODO: Apply filter
        case .liked:
            displayEstates = intent.state.estates
        case .todayEstates(let estates):
            displayEstates = estates
        case .hotEstates(let estates):
            displayEstates = estates
        }
    }

    /// 화면 높이에 따라 배너 간격을 동적으로 계산
    /// - 한 화면에 배너가 1~2개 보이도록 조정
    /// - Returns: 매물 카드 개수 단위 간격 (4~10 사이로 제한)
    private func calculateBannerInterval() -> Int {
        // 상수
        let estateCardHeight: CGFloat = 140  // EstateListItem 높이
        let cardSpacing: CGFloat = 12        // LazyVStack spacing
        let itemHeight = estateCardHeight + cardSpacing  // 152pt

        // 네비게이션 바 + 안전 영역 + 필터 칩 영역 (대략적인 추정)
        let navigationAndFilterHeight: CGFloat = 130

        // 사용 가능한 높이 계산
        let usableHeight = screenHeight - navigationAndFilterHeight

        // 화면당 보이는 카드 수
        let cardsPerScreen = usableHeight / itemHeight

        // 배너 간격 = 화면당 카드 수 / 2 (한 화면에 1~2개 배너)
        let calculatedInterval = Int(cardsPerScreen / 2)

        // 4~10 사이로 제한 (너무 촘촘하거나 드문 것 방지)
        let interval = max(4, min(10, calculatedInterval))

        print("📐 Banner interval calculated: \(interval) (screen height: \(screenHeight), cards per screen: \(cardsPerScreen))")

        return interval
    }
}

// MARK: - Estate List Item

struct EstateListItem: View {
    let estate: EstateSummaryResponse

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
            textStack
        }
        .padding(12)
        .frame(height: 140)
        .background(Color.gray0)
        .cornerRadius(20)
    }

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            // Image
            KFImage.auth(url: imageURL)
                .placeholder {
                    Color.gray30
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 108)
                .clipped()
                .cornerRadius(12)

            // Overlay Circle Button (20×20px)
            Circle()
                .fill(Color.deepCoast)
                .frame(width: 20, height: 20)
                .overlay {
                    Image(dsIcon: .focus)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(.gray0)
                }
                .offset(x: 8, y: 8)
        }
    }

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 1. Tag Badge
            tagBadge

            // 2. Title
            Text(estate.title)
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray90)
                .lineLimit(1)

            // 3. Price
            Text(priceText)
                .font(.pretendardBody2)
                .foregroundColor(.gray75)

            // 4. Meta (면적·층수)
            Text("\(Int(estate.area))㎡ · \(estate.floors)층")
                .font(.pretendardCaption2)
                .foregroundColor(.gray60)

            // 5. Distance (if available)
            if let distance = estate.distance {
                Text(distanceText(distance))
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
            .foregroundColor(.gray75)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Color.gray0)
            .overlay(
                Capsule()
                    .stroke(Color.gray45, lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    private var imageURL: URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: Secrets.baseURL + "/" + first)
    }

    private var priceText: String {
        if estate.monthly_rent > 0 {
            return "월세 \(formatPrice(estate.deposit))/\(formatPrice(estate.monthly_rent))"
        } else {
            return "전세 \(formatPrice(estate.deposit))"
        }
    }

    private func formatPrice(_ price: Int) -> String {
        if price >= 10000 {
            let billion = price / 10000
            let remainder = price % 10000
            if remainder == 0 {
                return "\(billion)억"
            } else {
                return "\(billion)억 \(remainder)"
            }
        }
        return "\(price)"
    }

    private func distanceText(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1fkm", meters / 1000)
        } else {
            return "\(Int(meters))m"
        }
    }
}

// MARK: - Inline Promo Item

struct InlinePromoItem: View {
    let banner: Banner
    let onTap: (String) -> Void

    var body: some View {
        Button {
            if let url = banner.actionUrl {
                onTap(url)
            }
        } label: {
            HStack(spacing: 0) {
                // Left: Text Block
                VStack(alignment: .leading, spacing: 4) {
                    Text(banner.title)
                        .font(.pretendardBody1Bold)
                        .foregroundColor(.gray90)
                        .lineLimit(2)

                    if banner.payload?.type == "WEBVIEW" {
                        Text("자세히 보기")
                            .font(.pretendardCaption1)
                            .foregroundColor(.gray60)
                    }
                }

                Spacer()

                // Right: Banner Image (64×64px)
                KFImage.auth(url: imageURL)
                    .placeholder {
                        Image(systemName: "star.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.brightCream)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(12)
            .frame(height: 72)
            .background(Color.gray0)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }

    private var imageURL: URL? {
        // 빈 문자열 체크
        guard !banner.image.isEmpty else {
            print("⚠️ [BANNER-UI] 이미지 경로가 비어있음")
            return nil
        }

        if banner.image.hasPrefix("http") {
            return URL(string: banner.image)
        } else {
            // 이중 슬래시 방지
            let separator = banner.image.hasPrefix("/") ? "" : "/"
            let fullPath = Secrets.baseURL + separator + banner.image
            print("🖼️ [BANNER-UI] URL 구성: '\(fullPath)'")
            return URL(string: fullPath)
        }
    }
}

#Preview("Map Mode") {
    NavigationStack {
        EstateListView(
            mode: .map(
                coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                estates: [],
                locationText: "서울시, 중구"
            )
        )
    }
}

#Preview("Liked Mode") {
    NavigationStack {
        EstateListView(mode: .liked)
    }
}
