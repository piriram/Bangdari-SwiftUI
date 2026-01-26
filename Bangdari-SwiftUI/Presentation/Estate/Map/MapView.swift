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
    var isImmediateActive: Bool = false
}

// MARK: - Map View

struct EstateMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var intent = MapIntent()

    @State private var position: MapCameraPosition = .region(.defaultRegion)
    @State private var viewState: MapViewState = .idle
    @State private var filterState = MapFilterState()
    @State private var selectedEstateIndex: Int = 0

    private var selectedEstate: EstateSummaryResponse? {
        guard !intent.state.estates.isEmpty,
              selectedEstateIndex < intent.state.estates.count else { return nil }
        return intent.state.estates[selectedEstateIndex]
    }

    var body: some View {
        ZStack {
            // Z1: Background
            Color.gray15.ignoresSafeArea()

            // Z2: Map
            mapContent
                .ignoresSafeArea()

            // Z3: Floating UI
            floatingUI

            // Z4: Navigation Bar
            navigationBar
        }
        .navigationBarHidden(true)
        .onAppear {
            intent.requestLocationPermission()
            Task { await intent.loadEstatesInCurrentRegion() }
        }
    }

    // MARK: - Z4: Navigation Bar

    private var navigationBar: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // 상단 row: 뒤로가기 / 위치 / 리스트전환
                HStack(spacing: 12) {
                    // 뒤로가기
                    Button { dismiss() } label: {
                        Image(dsIcon: .chevron)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray90)
                    }

                    // 위치 텍스트
                    HStack(spacing: 6) {
                        Image(dsIcon: .location)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.deepWood)

                        Text("문래역, 영등포구")
                            .font(.pretendardBody1Bold)
                            .foregroundColor(.gray90)
                    }

                    Spacer()

                    // 리스트 전환 버튼
                    Button {
                        // TODO: 리스트 뷰로 전환
                    } label: {
                        Image(dsIcon: .list)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray90)
                    }
                }

                // 검색 필드
                SearchBarButton(placeholder: "지역 또는 매물을 검색하세요", style: .bordered) {
                    // TODO: 검색 화면
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray0)

            Spacer()
        }
    }

    // MARK: - Z3: Floating UI

    private var floatingUI: some View {
        VStack(spacing: 0) {
            // NavBar 높이만큼 spacing
            Spacer().frame(height: 120)

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

            // 우측 하단: 로딩 + 줌 버튼 + 현위치 버튼
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    if intent.state.isLoading {
                        ProgressView()
                            .frame(width: 44, height: 44)
                            .background(Color.gray0)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }

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
            ForEach(intent.state.clusters) { cluster in
                Annotation(
                    cluster.isSingle ? (cluster.firstEstate?.title ?? "") : "\(cluster.count)개",
                    coordinate: cluster.coordinate
                ) {
                    clusterMarker(cluster)
                }
            }
            UserAnnotation()
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            intent.updateRegion(context.region)
            intent.updateClusters()

            // 지도 이동 시 S1로 전환 (S3, S4 제외)
            if !isEstateSelected && !isFilterAdjusting {
                viewState = .browsing
            }
        }
        .onTapGesture {
            // 지도 빈 영역 탭 시 선택 해제 → S1
            if isEstateSelected {
                withAnimation { viewState = .browsing }
            }
        }
    }

    // MARK: - Cluster / Marker

    private func clusterMarker(_ cluster: MapCluster) -> some View {
        Button {
            handleClusterTap(cluster)
        } label: {
            if cluster.isSingle, let estate = cluster.firstEstate {
                estateBubbleMarker(estate, isSelected: selectedEstate?.estate_id == estate.estate_id)
            } else {
                clusterBubble(cluster.count)
            }
        }
        .buttonStyle(.plain)
    }

    /// 단일 매물 마커 (가격 버블)
    private func estateBubbleMarker(_ estate: EstateSummaryResponse, isSelected: Bool) -> some View {
        VStack(spacing: 0) {
            Text(priceText(estate))
                .font(.pretendardCaption2)
                .fontWeight(.bold)
                .foregroundColor(.gray0)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.brightWood : Color.deepWood)
                .cornerRadius(6)

            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundColor(isSelected ? .brightWood : .deepWood)
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
    }

    /// 클러스터 마커 (원형 + 숫자)
    private func clusterBubble(_ count: Int) -> some View {
        ZStack {
            Circle()
                .fill(Color.deepCream.opacity(0.65))
                .frame(width: clusterSize(count) + 12, height: clusterSize(count) + 12)

            Circle()
                .fill(Color.deepCream)
                .frame(width: clusterSize(count), height: clusterSize(count))

            Text("\(count)")
                .font(.pretendardBody1Bold)
                .foregroundColor(.gray0)
        }
    }

    private func clusterSize(_ count: Int) -> CGFloat {
        if count >= 100 { return 60 }
        if count >= 50 { return 52 }
        return 44
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
                filterChip("즉시입주", isActive: filterState.isImmediateActive) {
                    filterState.isImmediateActive.toggle()
                    Task { await intent.loadEstatesInCurrentRegion() }
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
            return "\(formatPrice(filterState.depositRange.lowerBound)) ~ \(formatPrice(filterState.depositRange.upperBound))"
        case .monthlyRent:
            return "\(formatPrice(filterState.monthlyRentRange.lowerBound)) ~ \(formatPrice(filterState.monthlyRentRange.upperBound))"
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
                                // TODO: Navigate to EstateDetailView
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
        let currentSpan = intent.state.region.span
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(currentSpan.latitudeDelta / 2, 0.001),
            longitudeDelta: max(currentSpan.longitudeDelta / 2, 0.001)
        )
        position = .region(MKCoordinateRegion(
            center: intent.state.region.center,
            span: newSpan
        ))
    }

    private func zoomOut() {
        let currentSpan = intent.state.region.span
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(currentSpan.latitudeDelta * 2, 10),
            longitudeDelta: min(currentSpan.longitudeDelta * 2, 10)
        )
        position = .region(MKCoordinateRegion(
            center: intent.state.region.center,
            span: newSpan
        ))
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
            Image(dsIcon: .focus)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.gray90)
                .frame(width: 44, height: 44)
                .background(Color.gray0)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Actions

    private func handleClusterTap(_ cluster: MapCluster) {
        if cluster.isSingle, let estate = cluster.firstEstate {
            // 단일 매물 → S3
            if let index = intent.state.estates.firstIndex(where: { $0.estate_id == estate.estate_id }) {
                withAnimation {
                    selectedEstateIndex = index
                    viewState = .estateSelected(index)
                }
                position = .region(MKCoordinateRegion(
                    center: cluster.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        } else {
            // 클러스터 → S2 → 줌인
            viewState = .clusterFocused(cluster)
            let newSpan = MKCoordinateSpan(
                latitudeDelta: intent.state.region.span.latitudeDelta / 2,
                longitudeDelta: intent.state.region.span.longitudeDelta / 2
            )
            position = .region(MKCoordinateRegion(center: cluster.coordinate, span: newSpan))
        }
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

        withAnimation { viewState = .browsing }
        Task { await intent.loadEstatesInCurrentRegion() }
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
        let intValue = Int(value)
        if intValue >= 100_000_000 {
            let eok = intValue / 100_000_000
            let cheonman = (intValue % 100_000_000) / 10_000_000
            return cheonman > 0 ? "\(eok)억 \(cheonman)천만" : "\(eok)억"
        }
        if intValue >= 10_000_000 {
            return "\(intValue / 10_000_000)천만"
        }
        if intValue >= 1_000_000 {
            return "\(intValue / 1_000_000)백만"
        }
        return "\(intValue)"
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
