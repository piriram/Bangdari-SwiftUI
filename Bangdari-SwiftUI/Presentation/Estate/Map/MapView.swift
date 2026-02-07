import Kingfisher
import MapKit
import SwiftUI

// MARK: - View State

enum MapViewState: Equatable {
    case idle
    case browsing
    case clusterFocused(MapCluster)
    case estateSelected(Int) // 선택된 매물 인덱스
    case filterAdjusting(FilterType)

    enum FilterType: Equatable {
        case deposit
        case monthlyRent
        case area
    }

    static func == (lhs: MapViewState, rhs: MapViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.browsing, .browsing):
            return true
        case let (.clusterFocused(l), .clusterFocused(r)):
            return l.id == r.id
        case let (.estateSelected(l), .estateSelected(r)):
            return l == r
        case let (.filterAdjusting(l), .filterAdjusting(r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - Filter State

struct MapFilterState {
    var depositRange: ClosedRange<Double> = 0...100_000_000
    var monthlyRentRange: ClosedRange<Double> = 0...3_000_000
    var areaRange: ClosedRange<Double> = 0...100

    var isDepositActive: Bool = false
    var isMonthlyRentActive: Bool = false
    var isAreaActive: Bool = false
}

// MARK: - Navigation Data

struct MapNavigationData: Hashable {
    let category: EstateCategory?
    let initialCoordinate: CLLocationCoordinate2D?
    let coordinateSpan: MKCoordinateSpan?

    init(category: EstateCategory?, initialCoordinate: CLLocationCoordinate2D?, coordinateSpan: MKCoordinateSpan? = nil) {
        self.category = category
        self.initialCoordinate = initialCoordinate
        self.coordinateSpan = coordinateSpan
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(category?.rawValue)
        hasher.combine(initialCoordinate?.latitude)
        hasher.combine(initialCoordinate?.longitude)
        hasher.combine(coordinateSpan?.latitudeDelta)
    }

    static func == (lhs: MapNavigationData, rhs: MapNavigationData) -> Bool {
        lhs.category == rhs.category &&
        lhs.initialCoordinate?.latitude == rhs.initialCoordinate?.latitude &&
        lhs.initialCoordinate?.longitude == rhs.initialCoordinate?.longitude &&
        lhs.coordinateSpan?.latitudeDelta == rhs.coordinateSpan?.latitudeDelta
    }
}

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

        // MapIntent 초기화
        let mapIntent = MapIntent()
        _intent = StateObject(wrappedValue: mapIntent)

        // 초기 position 설정
        if let coord = initialCoordinate {
            let span = initialSpan ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            _position = State(initialValue: .region(MKCoordinateRegion(
                center: coord,
                span: span
            )))
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
            // 네비게이션 바
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

            // 지도 영역
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
                position = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: span
                ))
            }

            showSearchView = false
        }
    }

    // MARK: - Z3: Floating UI

    private var floatingUI: some View {
        VStack(spacing: 0) {
            // 필터 버튼 그룹 (S4가 아닐 때만 표시)
            if !isFilterAdjusting {
                filterButtonGroup
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            // S4: 필터 조정 패널
            if case .filterAdjusting(let type) = viewState {
                filterPanel(for: type)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // 우측 하단: 줌 버튼 + 현위치 버튼
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    // 줌 컨트롤
                    zoomControls

                    currentLocationButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, isEstateSelected ? 170 : 24)

            // S3: 하단 매물 카드 캐러셀
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
            // 실제 클러스터
            ForEach(intent.state.clusters) { cluster in
                Annotation(
                    cluster.isSingle ? (cluster.firstEstate?.title ?? "") : "\(cluster.count)개",
                    coordinate: cluster.coordinate
                ) {
                    clusterMarker(cluster)
                }
            }

            // 스켈레톤 클러스터 (로딩 중에만)
            ForEach(intent.state.skeletonClusters) { skeleton in
                Annotation("", coordinate: skeleton.coordinate) {
                    skeletonMarker
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
            // 대안 D: updateClusters 제거 → debounce 후에만 업데이트

            // 자동 캐러셀 표시 조건 체크
            checkAutoCarousel(for: context.region)

            // 지도 이동 시 S1로 전환 (S3, S4 제외)
            if !isEstateSelected && !isFilterAdjusting {
                viewState = .browsing
            }
        }
        .onTapGesture {
            // 필터 패널이 떠있으면 닫기 (우선순위 1)
            if isFilterAdjusting {
                withAnimation { viewState = .browsing }
            }
            // 매물이 선택되어 있으면 선택 해제 (우선순위 2)
            else if isEstateSelected {
                withAnimation { viewState = .browsing }
            }
        }
    }

    // MARK: - Cluster / Marker

    private func clusterMarker(_ cluster: MapCluster) -> some View {
        Button {
            handleClusterTap(cluster)
        } label: {
            if cluster.isSingle && intent.state.region.span.latitudeDelta < MapConstants.markerBalloonThreshold, let estate = cluster.firstEstate {
                // 충분히 확대된 상태에서만 말풍선 마커 표시
                EstateMarkerView(
                    estate: estate,
                    isSelected: selectedEstate?.estate_id == estate.estate_id
                )
            } else {
                clusterBubble(cluster.count)
            }
        }
        .buttonStyle(.plain)
    }

    /// 클러스터 마커 (원형 + 숫자) - 개수에 따라 크기 조정
    private func clusterBubble(_ count: Int) -> some View {
        ZStack {
            // 외곽 테두리 효과
            Circle()
                .fill(Color.deepCream.opacity(0.3))
                .frame(width: clusterSize(count) + 12, height: clusterSize(count) + 12)

            // 메인 원
            Circle()
                .fill(Color.deepCream.opacity(0.75))
                .frame(width: clusterSize(count), height: clusterSize(count))

            Text("\(count)")
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray0)
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: count)
    }

    /// 클러스터 크기 - 개수에 따라 동적 조정 (한 덩어리 효과)
    private func clusterSize(_ count: Int) -> CGFloat {
        if count >= 200 { return 120 }  // 매우 큰 클러스터
        if count >= 100 { return 90 }   // 큰 클러스터
        if count >= 50 { return 70 }    // 중간 클러스터
        if count >= 20 { return 56 }    // 작은 클러스터
        if count >= 10 { return 48 }    // 매우 작은 클러스터
        return 40                        // 최소 크기
    }

    /// 스켈레톤 마커 (로딩 중 플레이스홀더)
    private var skeletonMarker: some View {
        ZStack {
            Circle()
                .fill(Color.gray30.opacity(0.5))
                .frame(width: 44, height: 44)

            ProgressView()
                .tint(.gray60)
                .scaleEffect(0.8)
        }
    }

    // MARK: - Filter Button Group

    private var filterButtonGroup: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("보증금", isActive: filterState.isDepositActive) {
                    toggleFilter(.deposit)
                }
                filterChip("월세", isActive: filterState.isMonthlyRentActive) {
                    toggleFilter(.monthlyRent)
                }
                filterChip("평수", isActive: filterState.isAreaActive) {
                    toggleFilter(.area)
                }

                // 필터 초기화 버튼 (하나라도 활성화되어 있을 때만 표시)
                if filterState.isDepositActive || filterState.isMonthlyRentActive || filterState.isAreaActive {
                    Button {
                        resetFilters()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("초기화")
                                .font(.pretendardCaption1)
                        }
                        .foregroundColor(.gray75)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray15)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func filterChip(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendardCaption1)
                .foregroundColor(isActive ? .gray0 : .gray75)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isActive ? Color.deepWood : Color.gray0)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter Panel (S4)

    private func filterPanel(for type: MapViewState.FilterType) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Text(filterTitle(type))
                    .font(.pretendardBody2Bold)
                    .foregroundColor(.gray90)

                Spacer()

                Button("적용") {
                    applyFilter(type)
                }
                .font(.pretendardCaption1)
                .foregroundColor(.deepWood)
            }

            // 범위 표시
            Text(filterRangeText(type))
                .font(.pretendardBody2)
                .foregroundColor(.gray75)

            // Range Slider
            rangeSlider(for: type)
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private func filterTitle(_ type: MapViewState.FilterType) -> String {
        switch type {
        case .deposit: return "보증금 범위"
        case .monthlyRent: return "월세 범위"
        case .area: return "평수 범위"
        }
    }

    private func filterRangeText(_ type: MapViewState.FilterType) -> String {
        switch type {
        case .deposit:
            return "\(PriceFormatter.format(filterState.depositRange.lowerBound)) ~ \(PriceFormatter.format(filterState.depositRange.upperBound))"
        case .monthlyRent:
            return "\(PriceFormatter.format(filterState.monthlyRentRange.lowerBound)) ~ \(PriceFormatter.format(filterState.monthlyRentRange.upperBound))"
        case .area:
            return "\(Int(filterState.areaRange.lowerBound))평 ~ \(Int(filterState.areaRange.upperBound))평"
        }
    }

    @ViewBuilder
    private func rangeSlider(for type: MapViewState.FilterType) -> some View {
        switch type {
        case .deposit:
            RangeSliderView(
                lowerValue: Binding(
                    get: { filterState.depositRange.lowerBound },
                    set: { filterState.depositRange = $0...filterState.depositRange.upperBound }
                ),
                upperValue: Binding(
                    get: { filterState.depositRange.upperBound },
                    set: { filterState.depositRange = filterState.depositRange.lowerBound...$0 }
                ),
                bounds: 0...100_000_000
            )
        case .monthlyRent:
            RangeSliderView(
                lowerValue: Binding(
                    get: { filterState.monthlyRentRange.lowerBound },
                    set: { filterState.monthlyRentRange = $0...filterState.monthlyRentRange.upperBound }
                ),
                upperValue: Binding(
                    get: { filterState.monthlyRentRange.upperBound },
                    set: { filterState.monthlyRentRange = filterState.monthlyRentRange.lowerBound...$0 }
                ),
                bounds: 0...3_000_000
            )
        case .area:
            RangeSliderView(
                lowerValue: Binding(
                    get: { filterState.areaRange.lowerBound },
                    set: { filterState.areaRange = $0...filterState.areaRange.upperBound }
                ),
                upperValue: Binding(
                    get: { filterState.areaRange.upperBound },
                    set: { filterState.areaRange = filterState.areaRange.lowerBound...$0 }
                ),
                bounds: 0...100
            )
        }
    }

    // MARK: - Estate Card Carousel (S3)

    private var estateCardCarousel: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(intent.state.estates.enumerated()), id: \.element.estate_id) { index, estate in
                        estateCard(estate, isSelected: index == selectedEstateIndex)
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                            .id(index)
                            .onTapGesture {
                                // 카드 탭 → 상세 화면 이동
                                selectedEstateIdForDetail = estate.estate_id
                            }
                    }
                }
                .padding(.horizontal, 16)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 160)
            .onChange(of: selectedEstateIndex) { _, newIndex in
                // 카드 스크롤 동기화
                withAnimation(.easeInOut) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
                // 지도 이동
                if let estate = intent.state.estates[safe: newIndex] {
                    position = .region(MKCoordinateRegion(
                        center: estate.geolocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        // 스와이프로 카드 전환
                        let threshold: CGFloat = 50
                        if value.translation.width < -threshold {
                            selectNextEstate()
                        } else if value.translation.width > threshold {
                            selectPreviousEstate()
                        }
                    }
            )
            .padding(.bottom, 24)
        }
    }

    private func estateCard(_ estate: EstateSummaryResponse, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            // 이미지
            KFImage.auth(url: imageURL(estate))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // 정보
            VStack(alignment: .leading, spacing: 6) {
                // 카테고리 뱃지
                Text(estate.category)
                    .font(.pretendardCaption1)
                    .foregroundColor(.deepWood)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brightCream)
                    .cornerRadius(8)

                // 제목
                Text(estate.title)
                    .font(.pretendardBody2)
                    .foregroundColor(.gray90)
                    .lineLimit(1)

                // 가격 (title1)
                Text(priceText(estate))
                    .font(.pretendardTitle1)
                    .foregroundColor(.gray90)

                // 면적 + 위치
                HStack(spacing: 8) {
                    Text("\(String(format: "%.1f", estate.area))m²")
                        .font(.pretendardCaption1)
                        .foregroundColor(.gray75)

                    Text("·")
                        .foregroundColor(.gray60)

                    Text("영등포구") // TODO: 실제 주소
                        .font(.pretendardCaption1)
                        .foregroundColor(.gray60)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.gray0)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Zoom Controls

    private var zoomControls: some View {
        VStack(spacing: 0) {
            // 확대
            Button {
                zoomIn()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray90)
                    .frame(width: 44, height: 44)
            }

            Divider()
                .frame(width: 24)

            // 축소
            Button {
                zoomOut()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray90)
                    .frame(width: 44, height: 44)
            }
        }
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private func zoomIn() {
        print("🔍 [ZoomIn] 시작")
        let currentSpan = intent.state.region.span
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(currentSpan.latitudeDelta / 2, 0.001),
            longitudeDelta: max(currentSpan.longitudeDelta / 2, 0.001)
        )
        position = .region(MKCoordinateRegion(
            center: intent.state.region.center,
            span: newSpan
        ))

        // 줌 버튼도 즉시 클러스터 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            print("🔍 [ZoomIn] → 애니메이션 완료 후 updateClusters")
            intent.updateClusters()
        }
    }

    private func zoomOut() {
        print("🔍 [ZoomOut] 시작")
        let currentSpan = intent.state.region.span
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(currentSpan.latitudeDelta * 2, 10),
            longitudeDelta: min(currentSpan.longitudeDelta * 2, 10)
        )
        position = .region(MKCoordinateRegion(
            center: intent.state.region.center,
            span: newSpan
        ))

        // 줌아웃도 즉시 클러스터 업데이트
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            print("🔍 [ZoomOut] → 애니메이션 완료 후 updateClusters")
            intent.updateClusters()
        }
    }

    // MARK: - Current Location Button

    private var currentLocationButton: some View {
        Button {
            intent.moveToCurrentLocation()
            if let location = CLLocationManager().location {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
            }
        } label: {
            DSIconView(.focus, size: 20, renderingMode: .template)
                .foregroundColor(.gray90)
                .frame(width: 44, height: 44)
                .background(Color.gray0)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Actions

    private func handleClusterTap(_ cluster: MapCluster) {
        print("🎯 [Cluster Tap] ID: \(cluster.id), 매물 수: \(cluster.count), isSingle: \(cluster.isSingle)")

        if cluster.isSingle, let estate = cluster.firstEstate {
            let isBalloonMode = intent.state.region.span.latitudeDelta < MapConstants.markerBalloonThreshold

            if isBalloonMode {
                // 말풍선 탭 → EstateDetailView로 push
                print("🎯 [Cluster Tap] → 말풍선 탭, 디테일 이동")
                selectedEstateIdForDetail = estate.estate_id
            } else {
                // 클러스터 버튼 탭 → S3 (하단 카드 캐러셀)
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
            // 클러스터 → S2 → 클러스터 범위에 맞춰 줌인
            print("🎯 [Cluster Tap] → 클러스터 확대 시작")
            viewState = .clusterFocused(cluster)
            let fitRegion = regionToFitCluster(cluster)
            print("🎯 [Cluster Tap] → 지도 이동 실행")
            withAnimation(.easeInOut(duration: 0.3)) {
                position = .region(fitRegion)
            }

            // 줌인 후 즉시 클러스터 업데이트 (debounce 기다리지 않음)
            // 사용자 상호작용에는 즉각 반응
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                print("🎯 [Cluster Tap] → 애니메이션 완료 후 updateClusters")
                intent.updateClusters()
            }
        }
    }

    // MARK: - Auto Carousel

    /// 줌 레벨에 따라 캐러셀 자동 표시
    private func checkAutoCarousel(for region: MKCoordinateRegion) {
        let span = region.span.latitudeDelta

        // 조건: span < 0.05이고, 매물이 1개 이상 있고, 현재 browsing 상태일 때
        guard span < MapConstants.autoCarouselThreshold,
              !intent.state.estates.isEmpty,
              case .browsing = viewState else {
            return
        }

        print("🎠 [Auto Carousel] 조건 충족: span=\(String(format: "%.6f", span)), 매물 수=\(intent.state.estates.count)")

        // 화면 중앙에 가장 가까운 매물 찾기
        let centerCoordinate = region.center
        let nearestIndex = findNearestEstateIndex(to: centerCoordinate)

        print("🎠 [Auto Carousel] 가장 가까운 매물 인덱스: \(nearestIndex)")

        // S3로 전환 (캐러셀 표시)
        withAnimation {
            selectedEstateIndex = nearestIndex
            viewState = .estateSelected(nearestIndex)
        }
    }

    /// 화면 중앙에 가장 가까운 매물 인덱스 찾기
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

    /// 클러스터 내 모든 매물이 보이는 영역 계산
    private func regionToFitCluster(_ cluster: MapCluster) -> MKCoordinateRegion {
        let estates = cluster.estates
        guard !estates.isEmpty else {
            print("🔍 [Cluster Zoom] 빈 클러스터")
            return MKCoordinateRegion(center: cluster.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }

        let currentSpan = intent.state.region.span
        print("🔍 [Cluster Zoom] 시작 - 현재 span: \(String(format: "%.6f", currentSpan.latitudeDelta)), 매물 수: \(estates.count)")
        print("🔍 [Cluster Zoom] threshold: \(MapConstants.clusteringDisableThreshold)")

        // 이미 충분히 확대된 상태라면 개별 마커가 보이도록 강제 확대
        // threshold의 80% 이하면 거의 개별 마커 수준
        let nearThreshold = MapConstants.clusteringDisableThreshold * 1.2
        if currentSpan.latitudeDelta <= nearThreshold {
            // 개별 마커가 확실히 보이는 수준으로 확대
            let targetSpan = MapConstants.clusteringDisableThreshold * 0.6
            print("🔍 [Cluster Zoom] ✅ 분기1: 이미 충분히 확대됨 (\(String(format: "%.6f", currentSpan.latitudeDelta)) <= \(String(format: "%.6f", nearThreshold)))")
            print("🔍 [Cluster Zoom] → 강제 확대: \(String(format: "%.6f", targetSpan))")
            return MKCoordinateRegion(
                center: cluster.coordinate,
                span: MKCoordinateSpan(latitudeDelta: targetSpan, longitudeDelta: targetSpan)
            )
        }

        // 매물들의 좌표 범위 계산
        let lats = estates.map(\.geolocation.latitude)
        let lngs = estates.map(\.geolocation.longitude)

        let minLat = lats.min() ?? cluster.coordinate.latitude
        let maxLat = lats.max() ?? cluster.coordinate.latitude
        let minLng = lngs.min() ?? cluster.coordinate.longitude
        let maxLng = lngs.max() ?? cluster.coordinate.longitude

        let rawRangeLat = maxLat - minLat
        let rawRangeLng = maxLng - minLng
        print("🔍 [Cluster Zoom] 매물 범위 - lat: \(String(format: "%.6f", rawRangeLat)), lng: \(String(format: "%.6f", rawRangeLng))")

        // 중심점
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2

        // span 계산 (여유 공간 40% 추가)
        let estateRangeLat = max((maxLat - minLat) * 1.4, 0.005)
        let estateRangeLng = max((maxLng - minLng) * 1.4, 0.005)
        print("🔍 [Cluster Zoom] 매물 범위 (여유 40%): \(String(format: "%.6f", estateRangeLat))")

        // 무조건 2배 확대 vs 매물 범위에 맞춤 중 더 확대되는 것 선택
        let zoomInLat = currentSpan.latitudeDelta / 2
        let zoomInLng = currentSpan.longitudeDelta / 2
        print("🔍 [Cluster Zoom] 2배 확대: \(String(format: "%.6f", zoomInLat))")

        // 두 전략 중 더 확대되는 것 (더 작은 값) 선택
        var latDelta = min(estateRangeLat, zoomInLat)
        var lngDelta = min(estateRangeLng, zoomInLng)
        print("🔍 [Cluster Zoom] min(매물범위, 2배확대): \(String(format: "%.6f", latDelta))")

        // 개별 마커 threshold에 가까워지면 강제로 넘김
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
            // 같은 필터 다시 탭 → 닫기
            withAnimation { viewState = .browsing }
        } else {
            // 다른 필터 또는 새로 열기 → S4
            withAnimation { viewState = .filterAdjusting(type) }
        }
    }

    private func applyFilter(_ type: MapViewState.FilterType) {
        // 필터 활성 상태 업데이트
        switch type {
        case .deposit:
            filterState.isDepositActive = true
        case .monthlyRent:
            filterState.isMonthlyRentActive = true
        case .area:
            filterState.isAreaActive = true
        }

        // 클라이언트 측 필터링 적용
        intent.applyFilters(
            depositRange: filterState.depositRange,
            monthlyRentRange: filterState.monthlyRentRange,
            areaRange: filterState.areaRange,
            isDepositActive: filterState.isDepositActive,
            isMonthlyRentActive: filterState.isMonthlyRentActive,
            isAreaActive: filterState.isAreaActive
        )

        withAnimation { viewState = .browsing }
    }

    private func resetFilters() {
        // 모든 필터 비활성화
        filterState.isDepositActive = false
        filterState.isMonthlyRentActive = false
        filterState.isAreaActive = false

        // 필터 범위 초기화
        filterState.depositRange = 0...100_000_000
        filterState.monthlyRentRange = 0...3_000_000
        filterState.areaRange = 0...100

        // 원본 데이터 복원
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

    // MARK: - Formatting Helpers

    private func priceText(_ estate: EstateSummaryResponse) -> String {
        if estate.monthly_rent > 0 {
            return "\(formatShortPrice(estate.deposit))/\(estate.monthly_rent)"
        }
        return "전세 \(formatShortPrice(estate.deposit))"
    }

    private func formatShortPrice(_ value: Int) -> String {
        if value >= 10000 {
            return "\(value / 10000)억"
        }
        return "\(value)"
    }

    private func formatPrice(_ value: Double) -> String {
        return PriceFormatter.format(value)
    }

    private func imageURL(_ estate: EstateSummaryResponse) -> URL? {
        guard let first = estate.files.first else { return nil }
        return URL(string: Secrets.baseURL + "/" + first)
    }
}

// MARK: - Range Slider View

private struct RangeSliderView: View {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    let bounds: ClosedRange<Double>

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let range = bounds.upperBound - bounds.lowerBound
            let lowerX = CGFloat((lowerValue - bounds.lowerBound) / range) * width
            let upperX = CGFloat((upperValue - bounds.lowerBound) / range) * width

            ZStack(alignment: .leading) {
                // 비활성 바
                Capsule()
                    .fill(Color.gray30)
                    .frame(height: 4)

                // 활성 바
                Capsule()
                    .fill(Color.deepWood)
                    .frame(width: max(upperX - lowerX, 0), height: 4)
                    .offset(x: lowerX)

                // 시작 핸들
                sliderThumb
                    .position(x: lowerX, y: 10)
                    .gesture(
                        DragGesture().onChanged { value in
                            let clampedX = min(max(0, value.location.x), upperX - 20)
                            let newValue = bounds.lowerBound + (Double(clampedX / width) * range)
                            lowerValue = min(max(bounds.lowerBound, newValue), upperValue)
                        }
                    )

                // 끝 핸들
                sliderThumb
                    .position(x: upperX, y: 10)
                    .gesture(
                        DragGesture().onChanged { value in
                            let clampedX = max(min(width, value.location.x), lowerX + 20)
                            let newValue = bounds.lowerBound + (Double(clampedX / width) * range)
                            upperValue = max(min(bounds.upperBound, newValue), lowerValue)
                        }
                    )
            }
            .frame(height: 20)
        }
        .frame(height: 20)
    }

    private var sliderThumb: some View {
        Circle()
            .stroke(Color.deepWood, lineWidth: 2)
            .background(Circle().fill(Color.gray0))
            .frame(width: 20, height: 20)
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Extensions

extension EstateSummaryResponse: Identifiable {
    var id: String { estate_id }
}

extension Geolocation {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    NavigationStack {
        EstateMapView()
    }
}
