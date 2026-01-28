import Combine
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

    init(estateRepository: EstateRepository? = nil) {
        self.estateRepository = estateRepository ?? DIContainer.shared.makeEstateRepository()
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
}
