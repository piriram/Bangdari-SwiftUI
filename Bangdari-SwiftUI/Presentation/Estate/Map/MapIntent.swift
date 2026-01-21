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
    var maxDistance: Int = 3000  // 3km
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

    init(estateRepository: EstateRepository? = nil) {
        self.estateRepository = estateRepository ?? DIContainer.shared.makeEstateRepository()
        setupLocationManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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

    func updateRegion(_ region: MKCoordinateRegion) {
        state.region = region
    }

    func loadEstatesInCurrentRegion() async {
        await loadEstates(at: state.region.center)
    }

    func loadEstates(at center: CLLocationCoordinate2D) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let estates = try await estateRepository.fetchEstatesByLocation(
                latitude: center.latitude,
                longitude: center.longitude,
                maxDistance: state.maxDistance,
                category: state.selectedCategory
            )
            state.estates = estates
            updateClusters()
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "매물을 불러오는 중 오류가 발생했습니다."
        }

        state.isLoading = false
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
}
