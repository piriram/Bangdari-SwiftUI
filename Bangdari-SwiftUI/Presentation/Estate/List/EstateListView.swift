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
        CustomNavigationBar(onBack: { dismiss() }) {
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    filterChip(filter.title, isActive: activeFilter == filter) {
                        toggleFilter(filter)
                    }
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
        activeFilter = activeFilter == filter ? nil : filter
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
        displayEstates = mode.baseEstates ?? intent.state.estates
    }

    /// 화면 높이에 따라 배너 간격을 동적으로 계산
    /// - 한 화면에 배너가 1~2개 보이도록 조정
    /// - Returns: 매물 카드 개수 단위 간격 (4~10 사이로 제한)
    private func calculateBannerInterval() -> Int {
        let estateCardHeight: CGFloat = 124  // EstateListItem 높이
        let cardSpacing: CGFloat = 12
        let itemHeight = estateCardHeight + cardSpacing

        let navigationAndFilterHeight: CGFloat = 130
        let usableHeight = screenHeight - navigationAndFilterHeight
        let cardsPerScreen = usableHeight / itemHeight

        let calculatedInterval = Int(cardsPerScreen / 2)
        let interval = max(4, min(10, calculatedInterval))

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
