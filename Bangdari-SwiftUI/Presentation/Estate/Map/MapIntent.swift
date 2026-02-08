import Combine
import CoreLocation
import Foundation
import MapKit

// MARK: - Map Cluster

struct MapCluster: Identifiable, Equatable {
    let id: String  // 그리드 키 기반 (깜빡임 방지)
    let coordinate: CLLocationCoordinate2D
    let estates: [EstateSummaryResponse]

    var count: Int { estates.count }
    var isSingle: Bool { estates.count == 1 }
    var firstEstate: EstateSummaryResponse? { estates.first }

    static func == (lhs: MapCluster, rhs: MapCluster) -> Bool {
        lhs.id == rhs.id && lhs.count == rhs.count
    }
}

// MARK: - Map State

struct MapState {
    var estates: [EstateSummaryResponse] = []  // 필터링된 결과
    var allEstates: [EstateSummaryResponse] = []  // 원본 (필터 초기화용)
    var clusters: [MapCluster] = []
    var region: MKCoordinateRegion = .defaultRegion
    var isLoading: Bool = false
    var errorMessage: String?
    var selectedEstate: EstateSummaryResponse?

    // 필터
    var selectedCategory: String? = nil
    var maxDistance: Int = 15000  // 15km (넓은 범위로 확장)

    // Skeleton UI
    var skeletonClusters: [SkeletonCluster] = []

    // 위치 텍스트 (역지오코딩 결과)
    var locationText: String = "위치 정보 로딩 중..."

    // 검색
    var searchQuery: String = ""
}

// MARK: - Skeleton Clusㅌㅌter

struct SkeletonCluster: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Default Region (서울 중심)

extension MKCoordinateRegion {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
}

// MARK: - Map Constants

enum MapConstants {
    /// 이 값 이하로 확대하면 클러스터링 없이 개별 마커 표시
    /// 값이 작을수록 더 확대해야 개별 마커가 보임
    static let clusteringDisableThreshold: Double = 0.008

    /// 단일 클러스터가 말풍선으로 전환되는 줄기준
    /// span < 이 값 → 말풍선(EstateMarkerView), span >= 이 값 → 클러스터 버튼
    static let markerBalloonThreshold: Double = 0.03

    /// 캐러셀 자동 표시 임계값 (동 단위, 약 5.5km)
    /// span < 이 값 → 자동으로 하단 캐러셀 표시
    static let autoCarouselThreshold: Double = 0.05

    /// 자동 재조회 트리거 거리 (미터) - 3km로 증가하여 API 호출 빈도 감소
    static let reloadDistanceThreshold: Double = 3000

    /// debounce 시간 (밀리초)
    static let debounceMilliseconds: Int = 500
}

// MARK: - Estate Cache

final class EstateCache {
    private var cache: [String: CachedData] = [:]
    private let maxCacheCount = 50
    private let cacheValiditySeconds: TimeInterval = 300  // 5분

    struct CachedData {
        let estates: [EstateSummaryResponse]
        let timestamp: Date
        let region: MKCoordinateRegion
    }

    func get(for region: MKCoordinateRegion) -> [EstateSummaryResponse]? {
        let key = regionKey(region)

        guard let cached = cache[key] else { return nil }

        // 5분 이상 지나면 무효화
        let age = Date().timeIntervalSince(cached.timestamp)
        if age > cacheValiditySeconds {
            cache.removeValue(forKey: key)
            return nil
        }

        return cached.estates
    }

    func set(_ estates: [EstateSummaryResponse], for region: MKCoordinateRegion) {
        let key = regionKey(region)
        cache[key] = CachedData(estates: estates, timestamp: Date(), region: region)

        // 메모리 제한 (LRU - 가장 오래된 것 제거)
        if cache.count > maxCacheCount {
            let oldest = cache.min { $0.value.timestamp < $1.value.timestamp }
            if let key = oldest?.key {
                cache.removeValue(forKey: key)
            }
        }
    }

    /// Region을 그리드 기반 키로 변환 (약간의 이동도 같은 캐시 사용)
    private func regionKey(_ region: MKCoordinateRegion) -> String {
        // 0.01 단위로 스냅 (약 1km 정도의 그리드)
        let snapSize: Double = 0.01
        let snappedLat = round(region.center.latitude / snapSize) * snapSize
        let snappedLng = round(region.center.longitude / snapSize) * snapSize

        return "\(snappedLat),\(snappedLng)"
    }
}

// MARK: - Map Intent

@MainActor
final class MapIntent: ObservableObject {
    @Published private(set) var state = MapState()

    private let estateRepository: EstateRepository
    private let locationManager = CLLocationManager()
    private let estateCache = EstateCache()

    // Debounce를 위한 Combine
    private let regionSubject = PassthroughSubject<MKCoordinateRegion, Never>()
    private var cancellables = Set<AnyCancellable>()

    // 마지막 로드 위치 (중복 요청 방지)
    private var lastLoadedCenter: CLLocationCoordinate2D?

    init(estateRepository: EstateRepository? = nil) {
        self.estateRepository = estateRepository ?? DIContainer.shared.makeEstateRepository()
        setupLocationManager()
        setupRegionDebounce()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func setupRegionDebounce() {
        regionSubject
            .debounce(for: .milliseconds(MapConstants.debounceMilliseconds), scheduler: DispatchQueue.main)
            .sink { [weak self] region in
                guard let self else { return }
                Task {
                    await self.loadEstatesIfNeeded(at: region.center)
                    await self.updateLocationText(for: region.center)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 현재 위치로 이동 (초기 로드용)
    func initializeLocation() {
        // 위치 권한이 있으면 즉시 현재 위치로 이동
        if let location = locationManager.location {
//            print("📍 [initializeLocation] 현재 위치로 초기화: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            state.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )

            Task {
                await loadEstates(at: location.coordinate)
            }
        } else {
            // 위치 권한이 없으면 권한 요청
//            print("📍 [initializeLocation] 위치 권한 없음, 권한 요청")
            requestLocationPermission()
        }
    }

    func moveToCurrentLocation() {
        guard let location = locationManager.location else {
            requestLocationPermission()
            return
        }

        state.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )

        Task {
            await loadEstates(at: location.coordinate)
        }
    }

    /// 지도 영역 업데이트 + debounce로 자동 재조회
    func updateRegion(_ region: MKCoordinateRegion) {
        state.region = region

        // 일정 거리 이상 이동했으면 즉시 로딩 표시 (debounce 전에)
        if let lastCenter = lastLoadedCenter {
            let distance = distanceBetween(lastCenter, region.center)
//            print("🌍 [updateRegion] 이동 거리: \(String(format: "%.0f", distance))m (threshold: \(MapConstants.reloadDistanceThreshold)m)")
            if distance > MapConstants.reloadDistanceThreshold {
//                print("🌍 [updateRegion] → isLoading = true")
                state.isLoading = true
            }
        } else {
            print("🌍 [updateRegion] 첫 로딩")
        }

        regionSubject.send(region)
    }

    func loadEstatesInCurrentRegion() async {
        await loadEstates(at: state.region.center)
    }

    /// 일정 거리 이상 이동했을 때만 재조회
    private func loadEstatesIfNeeded(at center: CLLocationCoordinate2D) async {
//        print("⏱️ [loadEstatesIfNeeded] debounce 완료")
        // 마지막 로드 위치와 비교
        if let lastCenter = lastLoadedCenter {
            let distance = distanceBetween(lastCenter, center)
//            print("⏱️ [loadEstatesIfNeeded] 거리: \(String(format: "%.0f", distance))m (threshold: \(MapConstants.reloadDistanceThreshold)m)")
            guard distance > MapConstants.reloadDistanceThreshold else {
//                print("⏱️ [loadEstatesIfNeeded] → threshold 미만, updateClusters만 실행")
                updateClusters()
                return
            }
//            print("⏱️ [loadEstatesIfNeeded] → threshold 이상, API 호출")
        } else {
            print("⏱️ [loadEstatesIfNeeded] → 첫 로딩, API 호출")
        }

        await loadEstates(at: center)
    }

    func loadEstates(at center: CLLocationCoordinate2D) async {
//        print("💾 [loadEstates] 시작")
        // 1. 캐시 확인
        if let cached = estateCache.get(for: state.region) {
//            print("💾 [loadEstates] ✅ 캐시 히트! 매물 수: \(cached.count)")
            state.allEstates = cached  // 원본 저장
            state.estates = cached     // 표시용
            state.clusters = clusterEstates(cached, in: state.region)
            state.isLoading = false
            state.skeletonClusters = []
            lastLoadedCenter = center
            return  // 즉시 표시! 🚀
        }

        // 2. 캐시 미스 → 스켈레톤 표시
//        print("💾 [loadEstates] ❌ 캐시 미스, API 호출 시작")
        state.isLoading = true
        state.errorMessage = nil
        state.skeletonClusters = generateSkeletonGrid(for: state.region)
//        print("💾 [loadEstates] 스켈레톤 생성: \(state.skeletonClusters.count)개")

        do {
            let newEstates = try await estateRepository.fetchEstatesByLocation(
                latitude: center.latitude,
                longitude: center.longitude,
                maxDistance: state.maxDistance,
                category: state.selectedCategory
            )

//            print("💾 [loadEstates] ✅ API 성공! 매물 수: \(newEstates.count)")

            // 3. 캐시 저장
            estateCache.set(newEstates, for: state.region)
//            print("💾 [loadEstates] 캐시 저장 완료")

            // 4. 로딩 완료 후 한 번에 업데이트 (깜빡임 방지)
            state.isLoading = false
            state.allEstates = newEstates  // 원본 저장
            state.estates = newEstates     // 표시용
            state.skeletonClusters = []
            lastLoadedCenter = center
            updateClusters()
        } catch let error as NetworkError {
            print("💾 [loadEstates] ❌ API 실패 (NetworkError): \(error.message)")
            state.isLoading = false
            state.skeletonClusters = []
            state.errorMessage = error.message
        } catch {
            print("💾 [loadEstates] ❌ API 실패 (Unknown): \(error)")
            state.isLoading = false
            state.skeletonClusters = []
            state.errorMessage = "매물을 불러오는 중 오류가 발생했습니다."
        }
    }

    func selectEstate(_ estate: EstateSummaryResponse?) {
        state.selectedEstate = estate
    }

    func setCategory(_ category: String?) {
        state.selectedCategory = category
    }

    func setMaxDistance(_ distance: Int) {
        state.maxDistance = distance
    }

    func initializeWithCategory(_ category: EstateCategory?, at coordinate: CLLocationCoordinate2D?) {
        // 1. 카테고리 설정
        if let category = category {
            state.selectedCategory = category.rawValue
//            print("🗺️ [MapIntent] 초기 카테고리 설정: \(category.rawValue)")
        }

        // 2. 좌표 설정
        if let coord = coordinate {
            state.region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
//            print("🗺️ [MapIntent] 초기 좌표 설정: \(coord.latitude), \(coord.longitude)")
        }
    }

    // MARK: - Search

    func updateSearchQuery(_ query: String) {
        state.searchQuery = query
    }

    func searchEstates() async -> CLLocationCoordinate2D? {
        guard !state.searchQuery.isEmpty else {
            await loadEstatesInCurrentRegion()
            return nil
        }

        state.isLoading = true
        state.errorMessage = nil
//        print("🔍 [Search] 검색 시작: \(state.searchQuery)")

        // 검색어 보정: "구"나 "동"으로 끝나면 "서울특별시" 추가
        var searchQuery = state.searchQuery
        if searchQuery.hasSuffix("구") || searchQuery.hasSuffix("동") {
            // "서울" 또는 "서울특별시"가 이미 포함되어 있지 않으면 추가
            if !searchQuery.contains("서울") {
                searchQuery = "서울특별시 " + searchQuery
//                print("🔍 [Search] 검색어 보정: \(state.searchQuery) → \(searchQuery)")
            }
        }

        // 지역명으로 Geocoding
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(searchQuery)

            guard let coordinate = placemarks.first?.location?.coordinate else {
                state.errorMessage = "검색 결과가 없습니다. 지역명을 확인해주세요."
                state.isLoading = false
//                print("🔍 [Search] ❌ 검색 결과 없음")
                return nil
            }

            // 지역명 검색 성공 → 지도 이동
//            print("🔍 [Search] ✅ 지역명 검색 성공: \(searchQuery) → \(coordinate.latitude), \(coordinate.longitude)")

            state.region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )

            // 해당 위치의 매물 조회
            await loadEstates(at: coordinate)

//            print("🔍 [Search] 검색 완료")
            return coordinate  // 성공 시 좌표 반환
        } catch {
            state.errorMessage = "검색 중 오류가 발생했습니다"
            state.isLoading = false
            print("🔍 [Search] ❌ Geocoding 실패: \(error.localizedDescription)")
            return nil
        }
    }

    private func geocodeQuery(_ query: String) async -> (CLLocationCoordinate2D, MKCoordinateSpan)? {
        let geocoder = CLGeocoder()
        let seoulRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            radius: 30_000,
            identifier: "seoul"
        )

        do {
            // async 버전 사용 (region 파라미터 없음) → 결과를 서울 영역으로 필터링
            let placemarks = try await geocoder.geocodeAddressString(query, in: seoulRegion)

            guard let placemark = placemarks.first, let location = placemark.location else {
                print("🔍 [geocodeQuery] '\(query)' → 결과 없음")
                return nil
            }

            let coordinate = location.coordinate
            let latDelta: Double = placemark.subLocality != nil ? 0.015 : 0.04
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: latDelta)

//            print("🔍 [geocodeQuery] '\(query)' → \(coordinate.latitude), \(coordinate.longitude) span: \(latDelta)")
            return (coordinate, span)
        } catch {
            print("🔍 [geocodeQuery] '\(query)' 실패: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Clustering

    func updateClusters() {
        // 현재 estates 기준으로 클러스터 재계산 (줌 변경 시 즉시 반영)
        let newClusters = clusterEstates(state.estates, in: state.region)
//        print("🔄 [updateClusters] span: \(String(format: "%.6f", state.region.span.latitudeDelta)), estates: \(state.estates.count), 클러스터: \(state.clusters.count) → \(newClusters.count)")
        state.clusters = newClusters
    }

    /// 거리 기반 계층적 클러스터링 (한 덩어리 → 점진적 분산)
    private func clusterEstates(
        _ estates: [EstateSummaryResponse],
        in region: MKCoordinateRegion
    ) -> [MapCluster] {
        guard !estates.isEmpty else { return [] }

        // 충분히 확대되면 클러스터링 없이 개별 마커 표시
        let isDetailedZoom = region.span.latitudeDelta < MapConstants.clusteringDisableThreshold

        if isDetailedZoom {
            // 개별 마커로 표시 (각 매물이 하나의 클러스터)
//            print("📍 [Clustering] 개별 마커 모드 (span: \(String(format: "%.6f", region.span.latitudeDelta)) < threshold: \(MapConstants.clusteringDisableThreshold))")
            return estates.map { estate in
                MapCluster(
                    id: estate.estate_id,
                    coordinate: estate.geolocation.coordinate,
                    estates: [estate]
                )
            }
        }

        // 줌 레벨에 따라 클러스터 거리 임계값 동적 조정 (한 덩어리 효과)
        let clusterDistance = calculateClusterDistance(for: region)
//        print("📍 [Clustering] 거리 기반 모드 (span: \(String(format: "%.6f", region.span.latitudeDelta)), distance: \(String(format: "%.0f", clusterDistance))m)")

        // 거리 기반 클러스터링
        var remainingEstates = estates
        var clusters: [[EstateSummaryResponse]] = []

        while !remainingEstates.isEmpty {
            // 첫 번째 매물을 시드로 사용
            let seed = remainingEstates.removeFirst()
            var currentCluster = [seed]

            // 거리 임계값 내의 모든 매물을 같은 클러스터로 묶기
            remainingEstates = remainingEstates.filter { estate in
                let distance = distanceBetween(seed.geolocation.coordinate, estate.geolocation.coordinate)
                if distance <= clusterDistance {
                    currentCluster.append(estate)
                    return false // 클러스터에 추가되었으므로 제거
                }
                return true // 남겨둠
            }

            clusters.append(currentCluster)
        }

//        print("📍 [Clustering] 클러스터 개수: \(clusters.count)")

        // MapCluster로 변환
        return clusters.enumerated().map { index, groupedEstates in
            // 클러스터 중심 계산
            let avgLat = groupedEstates.map(\.geolocation.latitude).reduce(0, +) / Double(groupedEstates.count)
            let avgLng = groupedEstates.map(\.geolocation.longitude).reduce(0, +) / Double(groupedEstates.count)

            // 안정적인 ID 생성 (첫 번째 매물 ID + 카운트)
            let id = "cluster-\(groupedEstates.first?.estate_id ?? "unknown")-\(groupedEstates.count)"

            return MapCluster(
                id: id,
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng),
                estates: groupedEstates
            )
        }
    }

    /// 줌 레벨에 따라 클러스터 거리 임계값 계산
    private func calculateClusterDistance(for region: MKCoordinateRegion) -> Double {
        // span이 클수록 (줌 아웃) 더 넓은 범위를 클러스터링
        // span이 작을수록 (줌 인) 더 좁은 범위를 클러스터링

        let span = region.span.latitudeDelta

        // 줌 레벨별 거리 (미터)
        switch span {
        case 0.5...:        // 매우 넓은 범위 (도시 전체)
            return 5000     // 5km
        case 0.1..<0.5:     // 넓은 범위 (구 단위)
            return 2000     // 2km
        case 0.05..<0.1:    // 중간 범위 (여러 동)
            return 1000     // 1km
        case 0.02..<0.05:   // 좁은 범위 (동 단위)
            return 500      // 500m
        case 0.01..<0.02:   // 매우 좁은 범위 (동 일부)
            return 200      // 200m
        default:            // 개별 마커 표시 직전
            return 100      // 100m
        }
    }

    // MARK: - Skeleton UI

    /// 그리드 패턴으로 스켈레톤 클러스터 생성
    private func generateSkeletonGrid(for region: MKCoordinateRegion) -> [SkeletonCluster] {
        let gridSize = 4  // 4x4 그리드
        let stepLat = region.span.latitudeDelta / Double(gridSize + 1)
        let stepLng = region.span.longitudeDelta / Double(gridSize + 1)

        var skeletons: [SkeletonCluster] = []

        for i in 1...gridSize {
            for j in 1...gridSize {
                let lat = region.center.latitude - (region.span.latitudeDelta / 2) + (stepLat * Double(i))
                let lng = region.center.longitude - (region.span.longitudeDelta / 2) + (stepLng * Double(j))

                skeletons.append(SkeletonCluster(
                    id: "skeleton-\(i)-\(j)",
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                ))
            }
        }

        return skeletons
    }

    // MARK: - Helpers

    /// 두 좌표 간 거리 계산 (미터)
    private func distanceBetween(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: c1.latitude, longitude: c1.longitude)
        let loc2 = CLLocation(latitude: c2.latitude, longitude: c2.longitude)
        return loc1.distance(from: loc2)
    }

    /// 역지오코딩으로 위치 텍스트 업데이트
    private func updateLocationText(for coordinate: CLLocationCoordinate2D) async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            guard let placemark = placemarks.first else {
                state.locationText = formatCoordinate(coordinate)
                return
            }

            // "OO동, OO구" 형식 (예: "문래동, 영등포구")
            let subLocality = placemark.subLocality ?? "" // 동
            let locality = placemark.locality ?? ""       // 구

            if !subLocality.isEmpty && !locality.isEmpty {
                state.locationText = "\(subLocality), \(locality)"
            } else if !locality.isEmpty {
                state.locationText = locality
            } else {
                state.locationText = formatCoordinate(coordinate)
            }

            print("📍 [Geocoding] 위치: \(state.locationText)")
        } catch {
            print("📍 [Geocoding] 실패: \(error.localizedDescription)")
            state.locationText = formatCoordinate(coordinate)
        }
    }

    /// 좌표를 텍스트로 포맷 (역지오코딩 실패 시 대체)
    private func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude)
    }

    // MARK: - Filter

    /// 필터 적용 (클라이언트 측 필터링)
    func applyFilters(
        depositRange: ClosedRange<Double>,
        monthlyRentRange: ClosedRange<Double>,
        areaRange: ClosedRange<Double>,
        isDepositActive: Bool,
        isMonthlyRentActive: Bool,
        isAreaActive: Bool
    ) {
//        print("🔍 [Filter] 필터 적용 시작")
//        print("🔍 [Filter] 원본 매물 수: \(state.allEstates.count)")

        // 원본 데이터에서 필터링
        let filtered = state.allEstates.filter { estate in
            var passes = true

            // 보증금 필터
            if isDepositActive {
                let deposit = Double(estate.deposit)
                passes = passes && (deposit >= depositRange.lowerBound && deposit <= depositRange.upperBound)
            }

            // 월세 필터
            if isMonthlyRentActive {
                let rent = Double(estate.monthly_rent)
                passes = passes && (rent >= monthlyRentRange.lowerBound && rent <= monthlyRentRange.upperBound)
            }

            // 평수 필터
            if isAreaActive {
                passes = passes && (estate.area >= areaRange.lowerBound && estate.area <= areaRange.upperBound)
            }

            return passes
        }

//        print("🔍 [Filter] 필터링 결과: \(filtered.count)개")
        state.estates = filtered
        state.clusters = clusterEstates(filtered, in: state.region)
    }

    /// 필터 초기화
    func resetFilters() {
//        print("🔍 [Filter] 필터 초기화")
        state.estates = state.allEstates
        updateClusters()
    }
}

