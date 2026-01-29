import Combine
import Foundation

// MARK: - Estate Detail State

struct EstateDetailState {
    var estate: EstateDetailResponse?
    var similarEstates: [EstateSummaryResponse] = []
    var isLoading: Bool = false
    var isLikeLoading: Bool = false
    var errorMessage: String?

    // 채팅 관련 상태
    var isCreatingChatRoom: Bool = false
    var chatRoomError: String?
    var createdChatRoom: ChatRoomResponse?

    var isLiked: Bool {
        estate?.is_liked ?? false
    }
}

// MARK: - Estate Detail Intent

@MainActor
final class EstateDetailIntent: ObservableObject {
    @Published private(set) var state = EstateDetailState()

    private let estateRepository: EstateRepository
    private let chatRepository: ChatRepository
    private let estateId: String

    init(
        estateId: String,
        estateRepository: EstateRepository? = nil,
        chatRepository: ChatRepository? = nil
    ) {
        self.estateId = estateId
        self.estateRepository = estateRepository ?? DIContainer.shared.makeEstateRepository()
        self.chatRepository = chatRepository ?? DIContainer.shared.makeChatRepository()
    }

    // MARK: - Actions

    func loadDetail() async {
        print("🔍 [DEBUG] loadDetail 시작 - estateId: \(estateId)")
        state.isLoading = true
        state.errorMessage = nil

        do {
            async let detail = estateRepository.fetchEstateDetail(estateId: estateId)
            async let similar = estateRepository.fetchSimilarEstates()

            let detailResult = try await detail
            print("✅ [DEBUG] 상세 데이터 수신: \(detailResult.title)")
            print("✅ [DEBUG] files 개수: \(detailResult.files.count)")
            print("✅ [DEBUG] 옵션 데이터:")
            print("  - option1 (에어컨): \(detailResult.options.option1)")
            print("  - option2 (냉장고): \(detailResult.options.option2)")
            print("  - option3 (세탁기): \(detailResult.options.option3)")
            print("  - option4: \(detailResult.options.option4)")
            print("  - option5: \(detailResult.options.option5)")
            print("  - option6 (전자레인지): \(detailResult.options.option6)")
            print("  - option7: \(detailResult.options.option7)")
            print("  - option8: \(detailResult.options.option8)")
            print("  - option9 (옷장): \(detailResult.options.option9)")
            print("  - option10 (신발장): \(detailResult.options.option10)")
            state.estate = detailResult
            state.similarEstates = (try? await similar) ?? []
            print("✅ [DEBUG] 유사매물 개수: \(state.similarEstates.count)")
        } catch let error as NetworkError {
            print("❌ [DEBUG] NetworkError: \(error.message)")
            state.errorMessage = error.message
        } catch {
            print("❌ [DEBUG] Unknown Error: \(error)")
            state.errorMessage = "매물 정보를 불러오는 중 오류가 발생했습니다."
        }

        state.isLoading = false
        print("🔍 [DEBUG] loadDetail 종료 - estate: \(state.estate != nil ? "있음" : "없음"), error: \(state.errorMessage ?? "없음")")
    }

    func toggleLike() async {
        guard let estate = state.estate else { return }

        state.isLikeLoading = true

        do {
            _ = try await estateRepository.toggleLike(
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

    func createChatRoomWithAgent() async {
        guard let estate = state.estate else { return }

        state.isCreatingChatRoom = true
        state.chatRoomError = nil
        state.createdChatRoom = nil

        do {
            let room = try await chatRepository.createOrGetChatRoom(
                opponentId: estate.creator.user_id
            )
            state.createdChatRoom = room
        } catch let error as NetworkError {
            state.chatRoomError = error.message
        } catch {
            state.chatRoomError = "채팅방 생성에 실패했습니다."
        }

        state.isCreatingChatRoom = false
    }

    func clearChatRoomError() {
        state.chatRoomError = nil
    }
}
