import Combine
import CoreLocation
import Foundation

// MARK: - Home State

struct HomeState {
    // var banners: [Banner] = []  // Legacy: 배너 광고 API (사용 안 함)
    var todayEstates: [EstateSummaryResponse] = []
    var hotEstates: [EstateSummaryResponse] = []
    var topics: [EstateTopic] = []

    var isLoading: Bool = false
    var errorMessage: String?
}

// MARK: - Home Intent

@MainActor
final class HomeIntent: ObservableObject {
    @Published private(set) var state = HomeState()

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

    func loadHomeData() async {
        state.isLoading = true
        state.errorMessage = nil

        // 병렬로 모든 데이터 로드
        // async let bannersTask = loadBanners()  // Legacy: 배너 광고 API (사용 안 함)
        async let todayTask = loadTodayEstates()
        async let hotTask = loadHotEstates()
        async let topicsTask = loadTopics()

        _ = await (todayTask, hotTask, topicsTask)

        state.isLoading = false
    }

    /*
    // Legacy: 배너 광고 API (사용 안 함)
    private func loadBanners() async {
        do {
            state.banners = try await estateRepository.fetchMainBanners()
        } catch {
            // 배너 실패는 조용히 처리
        }
    }
    */

    private func loadTodayEstates() async {
        do {
            state.todayEstates = try await estateRepository.fetchTodayEstates()
        } catch {
            // 개별 섹션 실패는 조용히 처리
        }
    }

    private func loadHotEstates() async {
        do {
            state.hotEstates = try await estateRepository.fetchHotEstates()
        } catch {
            // 개별 섹션 실패는 조용히 처리
        }
    }

    private func loadTopics() async {
        do {
            state.topics = try await estateRepository.fetchTodayTopic()
        } catch {
            // 개별 섹션 실패는 조용히 처리
        }
    }

    func refresh() async {
        await loadHomeData()
    }

    // MARK: - Location

    func getCurrentCoordinate() -> CLLocationCoordinate2D? {
        // 위치 권한 확인
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        // 권한이 있고 위치를 사용할 수 있으면 현재 위치 반환
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways,
           let location = locationManager.location {
            print("📍 [HomeIntent] 현재 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            return location.coordinate
        }

        // 권한이 없거나 위치를 가져올 수 없으면 nil 반환
        print("📍 [HomeIntent] 위치 권한 없음 또는 위치 없음")
        return nil
    }
}
