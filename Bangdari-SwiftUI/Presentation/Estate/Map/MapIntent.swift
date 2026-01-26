import Combine
import CoreLocation
import Foundation
import MapKit

// MARK: - Map Cluster

struct MapCluster: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let estates: [EstateSummaryResponse]

    var count: Int { estates.count }
    var isSingle: Bool { estates.count == 1 }
    var firstEstate: EstateSummaryResponse? { estates.first }
}

// MARK: - Map State

struct MapState {
    var estates: [EstateSummaryResponse] = []
    var clusters: [MapCluster] = []
    var region: MKCoordinateRegion = .defaultRegion
    var isLoading: Bool = false
    var errorMessage: String?
    var selectedEstate: EstateSummaryResponse?

    // 필터
    var selectedCategory: String? = nil
    var maxDistance: Int = 5000  // 5km (확장)
}

// MARK: - Default Region (서울 중심)

extension MKCoordinateRegion {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
}

// MARK: - Map Intent

@MainActor
final class MapIntent: ObservableObject {
    @Published private(set) var state = MapState()

    private let estateRepository: EstateRepository
    private let locationManager = CLLocationManager()

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
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] region in
                guard let self else { return }
                Task {
                    await self.loadEstatesIfNeeded(at: region.center)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
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
        regionSubject.send(region)
    }

    func loadEstatesInCurrentRegion() async {
        await loadEstates(at: state.region.center)
    }

    /// 일정 거리 이상 이동했을 때만 재조회
    private func loadEstatesIfNeeded(at center: CLLocationCoordinate2D) async {
        // 마지막 로드 위치와 비교
        if let lastCenter = lastLoadedCenter {
            let distance = distanceBetween(lastCenter, center)
            // 500m 이상 이동했을 때만 재조회
            guard distance > 500 else {
                updateClusters()
                return
            }
        }

        await loadEstates(at: center)
    }

    func loadEstates(at center: CLLocationCoordinate2D) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let newEstates = try await estateRepository.fetchEstatesByLocation(
                latitude: center.latitude,
                longitude: center.longitude,
                maxDistance: state.maxDistance,
                category: state.selectedCategory
            )
            // 로딩 완료 후 한 번에 업데이트 (깜빡임 방지)
            state.isLoading = false
            state.estates = newEstates
            lastLoadedCenter = center
            updateClusters()
        } catch let error as NetworkError {
            state.isLoading = false
            state.errorMessage = error.message
        } catch {
            state.isLoading = false
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

    // MARK: - Clustering

    func updateClusters() {
        // 로딩 중이면 이전 클러스터 유지 (깜빡임 방지)
        guard !state.isLoading else { return }
        state.clusters = clusterEstates(state.estates, in: state.region)
    }

    /// 그리드 기반 클러스터링
    private func clusterEstates(
        _ estates: [EstateSummaryResponse],
        in region: MKCoordinateRegion
    ) -> [MapCluster] {
        guard !estates.isEmpty else { return [] }

        // 줌 레벨에 따라 클러스터 셀 크기 결정
        let cellSize = region.span.latitudeDelta / 10

        // 그리드 딕셔너리: (gridX, gridY) -> estates
        var grid: [String: [EstateSummaryResponse]] = [:]

        for estate in estates {
            let lat = estate.geolocation.latitude
            let lng = estate.geolocation.longitude

            let gridX = Int(floor(lng / cellSize))
            let gridY = Int(floor(lat / cellSize))
            let key = "\(gridX),\(gridY)"

            grid[key, default: []].append(estate)
        }

        // 클러스터 생성
        return grid.map { _, groupedEstates in
            // 클러스터 중심 계산
            let avgLat = groupedEstates.map(\.geolocation.latitude).reduce(0, +) / Double(groupedEstates.count)
            let avgLng = groupedEstates.map(\.geolocation.longitude).reduce(0, +) / Double(groupedEstates.count)

            return MapCluster(
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng),
                estates: groupedEstates
            )
        }
    }

    // MARK: - Helpers

    /// 두 좌표 간 거리 계산 (미터)
    private func distanceBetween(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: c1.latitude, longitude: c1.longitude)
        let loc2 = CLLocation(latitude: c2.latitude, longitude: c2.longitude)
        return loc1.distance(from: loc2)
    }
}
