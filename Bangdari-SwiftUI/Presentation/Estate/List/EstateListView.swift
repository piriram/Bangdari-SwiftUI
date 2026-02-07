import CoreLocation
import MapKit
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
    @State private var navigateToMap: Bool = false
    @State private var sortAscending: Bool = false  // false: 내림차순, true: 오름차순

    var body: some View {
        ZStack {
            // Z1: Full background
            Color.gray15.ignoresSafeArea()

            VStack(spacing: 0) {
                // Z2: Navigation Bar (System UI)
                navigationBar

                // Filter Chip Row (all modes)
                filterChipRow
                    .padding(.top, 12)

                // Z3: Single list sheet
                contentSheet
                    .padding(.top, 12)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedEstateIdForDetail) { estateId in
            EstateDetailView(estateId: estateId)
        }
        .navigationDestination(isPresented: $navigateToMap) {
            EstateMapView(
                initialCategory: nil,
                initialCoordinate: mapInitialCoordinate,
                initialSpan: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
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
        CustomNavigationBar(onBack: { dismiss() }, backgroundColor: .gray15) {
            HStack(spacing: NavBarStyle.centerSpacing) {
                DSIconView(.location, size: NavBarStyle.iconMedium, renderingMode: .template)
                    .foregroundColor(NavBarStyle.iconColor)

                Text(mode.navigationTitle)
                    .font(NavBarStyle.titleFont)
                    .foregroundColor(NavBarStyle.titleColor)
            }
        } trailing: {
            Button {
                navigateToMap = true
            } label: {
                DSIconView(.map, size: NavBarStyle.iconMedium, renderingMode: .template)
                    .foregroundColor(NavBarStyle.iconColor)
            }
        }
    }

    private var mapInitialCoordinate: CLLocationCoordinate2D {
        if let coordinate = mode.coordinate {
            return coordinate
        }

        return displayEstates.first?.geolocation.coordinate ?? .seoulCenter
    }

    // MARK: - Filter Chip Row

    private var filterChipRow: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        filterChip(filter.title, isActive: activeFilter == filter) {
                            toggleFilter(filter)
                        }
                    }
                }
                .padding(.leading, 16)
            }

            // 정렬 방향 토글 버튼
            Button {
                sortAscending.toggle()
                updateDisplayEstates()
            } label: {
                DSIconView(
                    .sort,
                    size: 24,
                    renderingMode: .template
                )
                .foregroundColor(activeFilter != nil ? .deepCoast : .gray60)
                .rotationEffect(.degrees(sortAscending ? 180 : 0))
                .animation(.easeInOut(duration: 0.2), value: sortAscending)
            }
            .padding(.trailing, 16)
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
                .clipShape(Capsule())
        }
    }

    private func toggleFilter(_ filter: FilterType) {
        activeFilter = activeFilter == filter ? nil : filter
        updateDisplayEstates()
    }

    // MARK: - Estate List Content

    private var contentSheet: some View {
        ZStack {
            Color.gray0

            if intent.state.isLoading && displayEstates.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if displayEstates.isEmpty {
                emptyView
            } else {
                estateListContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .cornerRadius(36, corners: [.topLeft, .topRight])
    }

    private var estateListContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(displayEstates.indices, id: \.self) { index in
                    estateRow(at: index)

                    if index < displayEstates.count - 1 {
                        itemDivider
                            .padding(.horizontal, 20)
                            .padding(.vertical, 0)
                    }
                }

                // Load more indicator (liked mode only)
                if case .liked = mode, intent.state.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func estateRow(at index: Int) -> some View {
        let estate = displayEstates[index]
        VStack(spacing: 12) {
            Button {
                selectedEstateIdForDetail = estate.estate_id
            } label: {
                EstateListItem(estate: estate)
            }
            .buttonStyle(.plain)

            // 동적 간격으로 배너 표시 (순환 로직)
            if let bannerPayload = bannerPayload(after: index) {
                InlinePromoItem(banner: bannerPayload.banner) { url in
                    // TODO: BannerWebView 네비게이션 구현
                    print("🔗 Banner clicked: \(url)")
                }
                .onAppear {
                    print("🔄 [BANNER-CYCLE] Estate #\(index) 뒤에 배너 표시")
                    print("  - Total Banners: \(intent.state.banners.count)")
                    print("  - Selected Index: \(bannerPayload.index)")
                    print("  - Banner Title: \(bannerPayload.banner.title)")
                }
            }
        }
    }

    private var itemDivider: some View {
        Rectangle()
            .fill(Color.gray30)
            .frame(height: 1)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "house")
                .font(.system(size: 48))
                .foregroundColor(.gray60)

            Text(mode.emptyMessage)
                .font(.pretendardBody2)
                .foregroundColor(.gray60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func loadInitialData() async {
        if case .liked = mode {
            await intent.loadMyLikedEstates()
            displayEstates = intent.state.estates
            return
        }

        displayEstates = mode.baseEstates ?? []
        await intent.loadBanners()
    }

    private func refresh() async {
        switch mode {
        case .map(let coordinate, _, _):
            await intent.loadEstates(at: coordinate)
            displayEstates = intent.state.estates
        case .liked:
            await intent.loadMyLikedEstates()
            displayEstates = intent.state.estates
        case .todayEstates, .hotEstates:
            displayEstates = mode.baseEstates ?? []
        }
    }

    private func updateDisplayEstates() {
        var estates = mode.baseEstates ?? intent.state.estates

        // 필터 적용
        if let filter = activeFilter {
            estates = applySorting(to: estates, filter: filter)
        }

        displayEstates = estates
    }

    private func applySorting(to estates: [EstateSummaryResponse], filter: FilterType) -> [EstateSummaryResponse] {
        let sorted: [EstateSummaryResponse]

        switch filter {
        case .area:
            // 면적 순
            sorted = estates.sorted { sortAscending ? $0.area < $1.area : $0.area > $1.area }

        case .deposit:
            // 보증금 순
            sorted = estates.sorted { sortAscending ? $0.deposit < $1.deposit : $0.deposit > $1.deposit }

        case .monthlyRent:
            // 월세 순
            sorted = estates.sorted { sortAscending ? $0.monthly_rent < $1.monthly_rent : $0.monthly_rent > $1.monthly_rent }

        case .immediate:
            // 신축 순
            sorted = estates.sorted { estate1, estate2 in
                // built_year가 빈 문자열이면 맨 뒤로
                if estate1.built_year.isEmpty { return false }
                if estate2.built_year.isEmpty { return true }
                return sortAscending ? estate1.built_year < estate2.built_year : estate1.built_year > estate2.built_year
            }
        }

        return sorted
    }

    private func bannerPayload(after index: Int) -> (index: Int, banner: Banner)? {
        guard index < displayEstates.count - 1, !intent.state.banners.isEmpty else { return nil }
        guard (index + 1) % bannerInterval == 0 else { return nil }

        let bannerIndex = ((index + 1) / bannerInterval) % intent.state.banners.count
        return (bannerIndex, intent.state.banners[bannerIndex])
    }

    /// 화면 높이에 따라 배너 간격을 동적으로 계산
    /// - 한 화면에 배너가 1~2개 보이도록 조정
    /// - Returns: 매물 카드 개수 단위 간격 (4~10 사이로 제한) -> 2 ~ 4
    private func calculateBannerInterval() -> Int {
        let estateCardHeight: CGFloat = 124  // EstateListItem 높이
        let cardSpacing: CGFloat = 12
        let itemHeight = estateCardHeight + cardSpacing

        let navigationAndFilterHeight: CGFloat = 130
        let usableHeight = screenHeight - navigationAndFilterHeight
        let cardsPerScreen = usableHeight / itemHeight

        let calculatedInterval = Int(cardsPerScreen / 2)
        let interval = max(2, min(4, calculatedInterval))

        print("📐 Banner interval calculated: \(interval) (screen height: \(screenHeight), cards per screen: \(cardsPerScreen))")

        return interval
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
