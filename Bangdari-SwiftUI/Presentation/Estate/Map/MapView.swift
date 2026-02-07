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

    var body: some View {
        VStack(spacing: 0) {
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

            ZStack {
                Color.gray15
                mapContent
                floatingUI

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

    // MARK: - Z3: Floating UI

    private var floatingUI: some View {
        VStack(spacing: 0) {
            MapFilterControlsView(
                filterState: $filterState,
                viewState: viewState,
                onToggleFilter: toggleFilter,
                onRangeChangedDebounced: applyFilterDebounced,
                onResetFilters: resetFilters
            )

            Spacer()

            HStack {
                Spacer()
                MapControlButtonsView(
                    onZoomIn: zoomIn,
                    onZoomOut: zoomOut,
                    onCurrentLocation: moveToCurrentLocation
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, isEstateSelected ? 170 : 24)

            if isEstateSelected {
                estateCardCarousel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewState)
    }

    // MARK: - Z2: Map Content

    private var mapContent: some View {
        Map(position: $position) {
            ForEach(intent.state.clusters) { cluster in
                Annotation(
                    cluster.isSingle ? (cluster.firstEstate?.title ?? "") : "\(cluster.count)개",
                    coordinate: cluster.coordinate
                ) {
                    clusterMarker(cluster)
                }
            }

            ForEach(intent.state.skeletonClusters) { skeleton in
                Annotation("", coordinate: skeleton.coordinate) {
                    MapSkeletonMarkerView()
                }
            }

            UserAnnotation()
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            print("📷 [Camera Change] span: \(String(format: "%.6f", context.region.span.latitudeDelta))")
            intent.updateRegion(context.region)
            checkAutoCarousel(for: context.region)

            if !isEstateSelected && !isFilterAdjusting {
                viewState = .browsing
            }
        }
        .onTapGesture {
            if isFilterAdjusting {
                withAnimation { viewState = .browsing }
            } else if isEstateSelected {
                withAnimation { viewState = .browsing }
            }
        }
    }

    // MARK: - Cluster / Marker

    private func clusterMarker(_ cluster: MapCluster) -> some View {
        Button {
            handleClusterTap(cluster)
        } label: {
            if cluster.isSingle,
               intent.state.region.span.latitudeDelta < MapConstants.markerBalloonThreshold,
               let estate = cluster.firstEstate {
                EstateMarkerView(
                    estate: estate,
                    isSelected: selectedEstate?.estate_id == estate.estate_id
                )
            } else {
                MapClusterBubbleView(count: cluster.count)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Estate Card Carousel (S3)

    private var estateCardCarousel: some View {
        MapEstateCardCarouselView(
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

        let currentSpan = intent.state.region.span
        let nextLatDelta = (currentSpan.latitudeDelta * scale).clamped(to: clamp)
        let nextLngDelta = (currentSpan.longitudeDelta * scale).clamped(to: clamp)

        position = .region(MKCoordinateRegion(
            center: intent.state.region.center,
            span: MKCoordinateSpan(latitudeDelta: nextLatDelta, longitudeDelta: nextLngDelta)
        ))

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
        } else {
            print("🎯 [Cluster Tap] → 클러스터 확대 시작")
            viewState = .clusterFocused(cluster)
            let fitRegion = regionToFitCluster(cluster)
            print("🎯 [Cluster Tap] → 지도 이동 실행")
            withAnimation(.easeInOut(duration: 0.3)) {
                position = .region(fitRegion)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                print("🎯 [Cluster Tap] → 애니메이션 완료 후 updateClusters")
                intent.updateClusters()
            }
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

        let centerCoordinate = region.center
        let nearestIndex = findNearestEstateIndex(to: centerCoordinate)

        print("🎠 [Auto Carousel] 가장 가까운 매물 인덱스: \(nearestIndex)")

        withAnimation {
            selectedEstateIndex = nearestIndex
            viewState = .estateSelected(nearestIndex)
        }
    }

    private func findNearestEstateIndex(to center: CLLocationCoordinate2D) -> Int {
        guard !intent.state.estates.isEmpty else { return 0 }

        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)

        var nearestIndex = 0
        var minDistance = Double.infinity

        for (index, estate) in intent.state.estates.enumerated() {
            let estateLocation = CLLocation(
                latitude: estate.geolocation.latitude,
                longitude: estate.geolocation.longitude
            )
            let distance = centerLocation.distance(from: estateLocation)

            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }

        print("🎠 [Nearest] 최단 거리: \(String(format: "%.0f", minDistance))m")
        return nearestIndex
    }

    // MARK: - Cluster Helpers

    private func regionToFitCluster(_ cluster: MapCluster) -> MKCoordinateRegion {
        let estates = cluster.estates
        guard !estates.isEmpty else {
            print("🔍 [Cluster Zoom] 빈 클러스터")
            return MKCoordinateRegion(
                center: cluster.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        let currentSpan = intent.state.region.span
        print("🔍 [Cluster Zoom] 시작 - 현재 span: \(String(format: "%.6f", currentSpan.latitudeDelta)), 매물 수: \(estates.count)")
        print("🔍 [Cluster Zoom] threshold: \(MapConstants.clusteringDisableThreshold)")

        let nearThreshold = MapConstants.clusteringDisableThreshold * 1.2
        if currentSpan.latitudeDelta <= nearThreshold {
            let targetSpan = MapConstants.clusteringDisableThreshold * 0.6
            print("🔍 [Cluster Zoom] ✅ 분기1: 이미 충분히 확대됨 (\(String(format: "%.6f", currentSpan.latitudeDelta)) <= \(String(format: "%.6f", nearThreshold)))")
            print("🔍 [Cluster Zoom] → 강제 확대: \(String(format: "%.6f", targetSpan))")
            return MKCoordinateRegion(
                center: cluster.coordinate,
                span: MKCoordinateSpan(latitudeDelta: targetSpan, longitudeDelta: targetSpan)
            )
        }

        let lats = estates.map(\.geolocation.latitude)
        let lngs = estates.map(\.geolocation.longitude)

        let minLat = lats.min() ?? cluster.coordinate.latitude
        let maxLat = lats.max() ?? cluster.coordinate.latitude
        let minLng = lngs.min() ?? cluster.coordinate.longitude
        let maxLng = lngs.max() ?? cluster.coordinate.longitude

        let rawRangeLat = maxLat - minLat
        let rawRangeLng = maxLng - minLng
        print("🔍 [Cluster Zoom] 매물 범위 - lat: \(String(format: "%.6f", rawRangeLat)), lng: \(String(format: "%.6f", rawRangeLng))")

        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2

        let estateRangeLat = max((maxLat - minLat) * 1.4, 0.005)
        let estateRangeLng = max((maxLng - minLng) * 1.4, 0.005)
        print("🔍 [Cluster Zoom] 매물 범위 (여유 40%): \(String(format: "%.6f", estateRangeLat))")

        let zoomInLat = currentSpan.latitudeDelta / 2
        let zoomInLng = currentSpan.longitudeDelta / 2
        print("🔍 [Cluster Zoom] 2배 확대: \(String(format: "%.6f", zoomInLat))")

        var latDelta = min(estateRangeLat, zoomInLat)
        var lngDelta = min(estateRangeLng, zoomInLng)
        print("🔍 [Cluster Zoom] min(매물범위, 2배확대): \(String(format: "%.6f", latDelta))")

        let targetThreshold = MapConstants.clusteringDisableThreshold * 0.8
        latDelta = min(latDelta, targetThreshold)
        lngDelta = min(lngDelta, targetThreshold)
        print("🔍 [Cluster Zoom] ✅ 분기2: 일반 확대 로직")
        print("🔍 [Cluster Zoom] → 최종 span: \(String(format: "%.6f", latDelta)) (threshold 강제: \(String(format: "%.6f", targetThreshold)))")
        print("🔍 [Cluster Zoom] → 변화: \(String(format: "%.6f", currentSpan.latitudeDelta)) → \(String(format: "%.6f", latDelta)) (비율: \(String(format: "%.2f", latDelta / currentSpan.latitudeDelta))x)")

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
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

    // MARK: - State Helpers

    private var isEstateSelected: Bool {
        if case .estateSelected = viewState { return true }
        return false
    }

    private var isFilterAdjusting: Bool {
        if case .filterAdjusting = viewState { return true }
        return false
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    NavigationStack {
        EstateMapView()
    }
}
