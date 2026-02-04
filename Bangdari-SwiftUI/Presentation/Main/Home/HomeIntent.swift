import Combine
import CoreLocation
import Foundation

// MARK: - Skeleton Data Models

struct SkeletonEstate: Identifiable {
    let id: String
}

struct SkeletonTopic: Identifiable {
    let id: String
}

// MARK: - Home State

struct HomeState {
    // 실제 데이터
    var todayEstates: [EstateSummaryResponse] = []
    var hotEstates: [EstateSummaryResponse] = []
    var topics: [EstateTopic] = []
    var banners: [Banner] = []

    // 스켈레톤 데이터 (로딩 중일 때만 존재)
    var todayEstateSkeletons: [SkeletonEstate] = []
    var hotEstateSkeletons: [SkeletonEstate] = []
    var topicSkeletons: [SkeletonTopic] = []
    var heroBannerSkeleton: Bool = false

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

        // 스켈레톤 생성
        state.heroBannerSkeleton = true
        state.todayEstateSkeletons = generateEstateSkeletons(count: 3)
        state.hotEstateSkeletons = generateEstateSkeletons(count: 2)
        state.topicSkeletons = generateTopicSkeletons(count: 4)

        // 병렬로 모든 데이터 로드
        async let todayTask = loadTodayEstates()
        async let hotTask = loadHotEstates()
        async let topicsTask = loadTopics()
        async let bannersTask = loadBanners()

        _ = await (todayTask, hotTask, topicsTask, bannersTask)

        // 모든 로딩 완료
        state.isLoading = false
    }

    private func loadTodayEstates() async {
        do {
            let estates = try await estateRepository.fetchTodayEstates()
            state.todayEstates = estates
            // 개별 완료 시 해당 스켈레톤만 제거
            state.todayEstateSkeletons = []
            state.heroBannerSkeleton = false
        } catch {
            // 실패해도 스켈레톤 제거 (빈 상태 표시)
            state.todayEstateSkeletons = []
            state.heroBannerSkeleton = false
        }
    }

    private func loadHotEstates() async {
        do {
            let estates = try await estateRepository.fetchHotEstates()
            state.hotEstates = estates
            state.hotEstateSkeletons = []
        } catch {
            state.hotEstateSkeletons = []
        }
    }

    private func loadTopics() async {
        do {
            let topics = try await estateRepository.fetchTodayTopic()
            state.topics = topics
            state.topicSkeletons = []
        } catch {
            state.topicSkeletons = []
        }
    }

    private func loadBanners() async {
        do {
            let banners = try await estateRepository.fetchMainBanners()
            state.banners = banners
        } catch {
            // Banner 로드 실패 시 무시
        }
    }

    func refresh() async {
        await loadHomeData()
    }

    // MARK: - Skeleton Generators

    private func generateEstateSkeletons(count: Int) -> [SkeletonEstate] {
        (0..<count).map { SkeletonEstate(id: "skeleton-\($0)") }
    }

    private func generateTopicSkeletons(count: Int) -> [SkeletonTopic] {
        (0..<count).map { SkeletonTopic(id: "skeleton-\($0)") }
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
