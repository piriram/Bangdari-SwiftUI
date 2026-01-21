import Combine
import CoreLocation
import Foundation

// MARK: - Estate List State

struct EstateListState {
    var estates: [EstateSummaryResponse] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String?

    // 페이지네이션
    var nextCursor: String? = nil
    var hasMore: Bool = true

    // 필터
    var selectedCategory: String? = nil

    // 위치
    var currentLocation: CLLocationCoordinate2D?
    var maxDistance: Int = 5000  // 기본 5km
}

// MARK: - Estate List Intent

@MainActor
final class EstateListIntent: ObservableObject {
    @Published private(set) var state = EstateListState()

    private let estateRepository: EstateRepository
    private let locationManager = CLLocationManager()

    init(estateRepository: EstateRepository? = nil) {
        self.estateRepository = estateRepository ?? DIContainer.shared.makeEstateRepository()
    }

    // MARK: - Actions

    func loadEstates(at location: CLLocationCoordinate2D) async {
        state.isLoading = true
        state.errorMessage = nil
        state.currentLocation = location

        do {
            let estates = try await estateRepository.fetchEstatesByLocation(
                latitude: location.latitude,
                longitude: location.longitude,
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

    func loadMyLikedEstates() async {
        state.isLoading = true
        state.errorMessage = nil
        state.nextCursor = nil
        state.hasMore = true

        do {
            let response = try await estateRepository.fetchMyLikedEstates(
                next: nil,
                limit: 20,
                category: state.selectedCategory
            )
            state.estates = response.data
            state.nextCursor = response.next_cursor
            state.hasMore = response.hasMore
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "좋아요 매물을 불러오는 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func loadMoreLikedEstates() async {
        guard !state.isLoadingMore, state.hasMore, let cursor = state.nextCursor else { return }

        state.isLoadingMore = true

        do {
            let response = try await estateRepository.fetchMyLikedEstates(
                next: cursor,
                limit: 20,
                category: state.selectedCategory
            )
            state.estates.append(contentsOf: response.data)
            state.nextCursor = response.next_cursor
            state.hasMore = response.hasMore
        } catch {
            // 추가 로딩 실패는 조용히 처리
        }

        state.isLoadingMore = false
    }

    func setCategory(_ category: String?) {
        state.selectedCategory = category
    }

    func setMaxDistance(_ distance: Int) {
        state.maxDistance = distance
    }

    func refresh() async {
        if let location = state.currentLocation {
            await loadEstates(at: location)
        }
    }
}
