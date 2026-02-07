import MapKit
import SwiftUI

// MARK: - Map View

struct EstateMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var intent: MapIntent

    let initialCategory: EstateCategory?
    let initialCoordinate: CLLocationCoordinate2D?
    let initialSpan: MKCoordinateSpan?

    @State private var position: MapCameraPosition
    @State private var viewState: MapViewState = .idle
    @State private var filterState = MapFilterState()
    @State private var selectedEstateIndex: Int = 0
    @State private var selectedEstateIdForDetail: String?
    @State private var navigateToList: Bool = false
    @State private var showSearchView = false

    init(initialCategory: EstateCategory? = nil, initialCoordinate: CLLocationCoordinate2D? = nil, initialSpan: MKCoordinateSpan? = nil) {
        self.initialCategory = initialCategory
        self.initialCoordinate = initialCoordinate
        self.initialSpan = initialSpan

        let mapIntent = MapIntent()
        _intent = StateObject(wrappedValue: mapIntent)

        if let coord = initialCoordinate {
            let span = initialSpan ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            _position = State(initialValue: .region(MKCoordinateRegion(center: coord, span: span)))
        } else {
            _position = State(initialValue: .region(.defaultRegion))
        }
    }

    private var selectedEstate: EstateSummaryResponse? {
        guard !intent.state.estates.isEmpty,
              selectedEstateIndex < intent.state.estates.count else { return nil }
        return intent.state.estates[selectedEstateIndex]
    }

    private var isEstateSelected: Bool {
        if case .estateSelected = viewState { return true }
        return false
    }

    private var isFilterAdjusting: Bool {
        if case .filterAdjusting = viewState { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ZStack {
                Color.gray15

                MapSceneView(
                    position: $position,
                    clusters: intent.state.clusters,
                    skeletonClusters: intent.state.skeletonClusters,
                    regionSpan: intent.state.region.span.latitudeDelta,
                    selectedEstate: selectedEstate,
                    onClusterTap: handleClusterTap,
                    onMapCameraChange: handleMapCameraChange,
                    onMapTap: handleMapTap
                )

                MapFloatingOverlayView(
                    filterState: $filterState,
                    viewState: viewState,
                    onToggleFilter: toggleFilter,
                    onRangeChangedDebounced: applyFilterDebounced,
                    onResetFilters: resetFilters,
                    onZoomIn: zoomIn,
                    onZoomOut: zoomOut,
                    onCurrentLocation: moveToCurrentLocation,
                    isEstateSelected: isEstateSelected,
                    estates: intent.state.estates,
                    selectedEstateIndex: $selectedEstateIndex,
                    onCardTap: { estate in
                        selectedEstateIdForDetail = estate.estate_id
                    },
                    onSwipeNext: selectNextEstate,
                    onSwipePrevious: selectPreviousEstate,
                    onSelectionChanged: { estate in
                        position = .region(MKCoordinateRegion(
                            center: estate.geolocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                )

                if intent.state.isLoading && intent.state.skeletonClusters.isEmpty {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(width: 60, height: 60)
                        .background(Color.gray0.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            intent.initializeWithCategory(initialCategory, at: initialCoordinate)
            if initialCoordinate == nil {
                intent.initializeLocation()
            } else {
                intent.requestLocationPermission()
                Task { await intent.loadEstatesInCurrentRegion() }
            }
        }
        .onChange(of: intent.state.region.center.latitude) { _, _ in
            position = .region(intent.state.region)
        }
        .navigationDestination(item: $selectedEstateIdForDetail) { estateId in
            EstateDetailView(estateId: estateId)
        }
        .navigationDestination(isPresented: $navigateToList) {
            EstateListView(
                mode: .map(
                    coordinate: intent.state.region.center,
                    estates: intent.state.estates,
                    locationText: intent.state.locationText
                )
            )
        }
        .navigationDestination(isPresented: $showSearchView) {
            SearchView()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SearchCompleted"))) { notification in
            guard let coordinate = notification.userInfo?["coordinate"] as? CLLocationCoordinate2D,
                  let span = notification.userInfo?["span"] as? MKCoordinateSpan else { return }

            withAnimation(.easeInOut(duration: 0.5)) {
                position = .region(MKCoordinateRegion(center: coordinate, span: span))
            }

            showSearchView = false
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        CustomNavigationBar(onBack: { dismiss() }) {
            Button {
                // TODO: 위치 선택 모달
            } label: {
                HStack(spacing: NavBarStyle.centerSpacing) {
                    DSIconView(.location, size: NavBarStyle.iconMedium, renderingMode: .template)
                        .foregroundColor(NavBarStyle.iconColor)
                    Text(intent.state.locationText)
                        .font(NavBarStyle.titleFont)
                        .foregroundColor(NavBarStyle.iconColor)
                }
            }
        } trailing: {
            HStack(spacing: NavBarStyle.trailingSpacing) {
                Button {
                    showSearchView = true
                } label: {
                    DSIconView(.search, size: NavBarStyle.iconMedium, renderingMode: .template)
                        .foregroundColor(NavBarStyle.iconColor)
                }

                Button {
                    navigateToList = true
                } label: {
                    DSIconView(.list, size: NavBarStyle.iconMedium, renderingMode: .template)
                        .foregroundColor(NavBarStyle.iconColor)
                }
            }
        }
    }

    // MARK: - Map Events

    private func handleMapCameraChange(_ region: MKCoordinateRegion) {
        print("📷 [Camera Change] span: \(String(format: "%.6f", region.span.latitudeDelta))")
        intent.updateRegion(region)
        checkAutoCarousel(for: region)

        if !isEstateSelected && !isFilterAdjusting {
            viewState = .browsing
        }
    }

    private func handleMapTap() {
        if isFilterAdjusting || isEstateSelected {
            withAnimation { viewState = .browsing }
        }
    }

    // MARK: - Actions

    private func moveToCurrentLocation() {
        intent.moveToCurrentLocation()

        if let location = CLLocationManager().location {
            position = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    private func zoomIn() {
        updateZoom(scale: 0.5, clamp: 0.001...10, logPrefix: "ZoomIn")
    }

    private func zoomOut() {
        updateZoom(scale: 2.0, clamp: 0.001...10, logPrefix: "ZoomOut")
    }

    private func updateZoom(scale: Double, clamp: ClosedRange<Double>, logPrefix: String) {
        print("🔍 [\(logPrefix)] 시작")

        let nextRegion = MapViewHelpers.zoomRegion(
            from: intent.state.region,
            scale: scale,
            clamp: clamp
        )
        position = .region(nextRegion)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            print("🔍 [\(logPrefix)] → 애니메이션 완료 후 updateClusters")
            intent.updateClusters()
        }
    }

    private func handleClusterTap(_ cluster: MapCluster) {
        print("🎯 [Cluster Tap] ID: \(cluster.id), 매물 수: \(cluster.count), isSingle: \(cluster.isSingle)")

        if cluster.isSingle, let estate = cluster.firstEstate {
            let isBalloonMode = intent.state.region.span.latitudeDelta < MapConstants.markerBalloonThreshold

            if isBalloonMode {
                print("🎯 [Cluster Tap] → 말풍선 탭, 디테일 이동")
                selectedEstateIdForDetail = estate.estate_id
            } else {
                print("🎯 [Cluster Tap] → 단일 클러스터 버튼 탭, S3 표시")
                if let index = intent.state.estates.firstIndex(where: { $0.estate_id == estate.estate_id }) {
                    withAnimation {
                        selectedEstateIndex = index
                        viewState = .estateSelected(index)
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        position = .region(MKCoordinateRegion(
                            center: cluster.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
            }
            return
        }

        print("🎯 [Cluster Tap] → 클러스터 확대 시작")
        viewState = .clusterFocused(cluster)

        let fitRegion = MapViewHelpers.regionToFitCluster(
            cluster,
            currentSpan: intent.state.region.span
        )

        print("🎯 [Cluster Tap] → 지도 이동 실행")
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(fitRegion)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            print("🎯 [Cluster Tap] → 애니메이션 완료 후 updateClusters")
            intent.updateClusters()
        }
    }

    // MARK: - Auto Carousel

    private func checkAutoCarousel(for region: MKCoordinateRegion) {
        let span = region.span.latitudeDelta

        guard span < MapConstants.autoCarouselThreshold,
              !intent.state.estates.isEmpty,
              case .browsing = viewState else {
            return
        }

        print("🎠 [Auto Carousel] 조건 충족: span=\(String(format: "%.6f", span)), 매물 수=\(intent.state.estates.count)")

        let nearest = MapViewHelpers.nearestEstateIndex(
            estates: intent.state.estates,
            to: region.center
        )

        print("🎠 [Auto Carousel] 가장 가까운 매물 인덱스: \(nearest.index)")
        print("🎠 [Nearest] 최단 거리: \(String(format: "%.0f", nearest.distance))m")

        withAnimation {
            selectedEstateIndex = nearest.index
            viewState = .estateSelected(nearest.index)
        }
    }

    private func toggleFilter(_ type: MapViewState.FilterType) {
        if case .filterAdjusting(let current) = viewState, current == type {
            withAnimation { viewState = .browsing }
        } else {
            withAnimation { viewState = .filterAdjusting(type) }
        }
    }

    private func applyFilterDebounced(_ type: MapViewState.FilterType) {
        filterState.activate(type)

        intent.applyFilters(
            depositRange: filterState.depositRange,
            monthlyRentRange: filterState.monthlyRentRange,
            areaRange: filterState.areaRange,
            isDepositActive: filterState.isDepositActive,
            isMonthlyRentActive: filterState.isMonthlyRentActive,
            isAreaActive: filterState.isAreaActive
        )
    }

    private func resetFilters() {
        filterState.reset()
        intent.resetFilters()
        withAnimation { viewState = .browsing }
    }

    private func selectNextEstate() {
        guard !intent.state.estates.isEmpty else { return }
        let nextIndex = min(selectedEstateIndex + 1, intent.state.estates.count - 1)
        selectedEstateIndex = nextIndex
        viewState = .estateSelected(nextIndex)
    }

    private func selectPreviousEstate() {
        guard !intent.state.estates.isEmpty else { return }
        let prevIndex = max(selectedEstateIndex - 1, 0)
        selectedEstateIndex = prevIndex
        viewState = .estateSelected(prevIndex)
    }
}

#Preview {
    NavigationStack {
        EstateMapView()
    }
}
