import Combine
import Foundation

// MARK: - Estate Detail State

struct EstateDetailState {
    var estate: EstateDetailResponse?
    var isLoading: Bool = false
    var isLikeLoading: Bool = false
    var errorMessage: String?

    var isLiked: Bool {
        estate?.is_liked ?? false
    }
}

// MARK: - Estate Detail Intent

@MainActor
final class EstateDetailIntent: ObservableObject {
    @Published private(set) var state = EstateDetailState()

    private let estateRepository: EstateRepository
    private let estateId: String

    init(
        estateId: String,
        estateRepository: EstateRepository = DIContainer.shared.makeEstateRepository()
    ) {
        self.estateId = estateId
        self.estateRepository = estateRepository
    }

    // MARK: - Actions

    func loadDetail() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.estate = try await estateRepository.fetchEstateDetail(estateId: estateId)
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "매물 정보를 불러오는 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func toggleLike() async {
        guard let estate = state.estate else { return }

        state.isLikeLoading = true

        do {
            let newStatus = try await estateRepository.toggleLike(
                estateId: estateId,
                like: !estate.is_liked
            )
            // 상태 업데이트를 위해 다시 로드
            await loadDetail()
        } catch {
            // 좋아요 실패는 조용히 처리
        }

        state.isLikeLoading = false
    }
}
