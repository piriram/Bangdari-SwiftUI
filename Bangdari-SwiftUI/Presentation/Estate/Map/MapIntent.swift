import Combine
import CoreLocation
import Foundation
import MapKit

// MARK: - Map State

struct MapState {
    var estates: [EstateSummaryResponse] = []
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

    init(estateRepository: EstateRepository = DIContainer.shared.makeEstateRepository()) {
        self.estateRepository = estateRepository
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
}
