import Foundation
import Combine

// MARK: - State

struct EstateCommentState {
    var estate: EstateDetailResponse?
    var isLoading: Bool = false
    var isCommentLoading: Bool = false
    var errorMessage: String?

    // 댓글 입력
    var commentText: String = ""
    var replyingTo: EstateComment? = nil

    var comments: [EstateComment] {
        estate?.comments ?? []
    }
}

// MARK: - Intent

@MainActor
final class EstateCommentIntent: ObservableObject {
    @Published private(set) var state = EstateCommentState()

    private let estateId: String
    private let estateRepository: EstateRepository

    init(estateId: String, estateRepository: EstateRepository? = nil) {
        self.estateId = estateId
        self.estateRepository = estateRepository ?? DIContainer.shared.makeEstateRepository()
    }

    // MARK: - Load

    func loadComments() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let detail = try await estateRepository.fetchEstateDetail(estateId: estateId)
            state.estate = detail
        } catch {
            state.errorMessage = "댓글을 불러오는데 실패했습니다."
        }

        state.isLoading = false
    }

    // MARK: - Comment Input

    func updateCommentText(_ text: String) {
        state.commentText = text
    }

    func setReplyingTo(_ comment: EstateComment?) {
        state.replyingTo = comment
    }

    // MARK: - Submit

    func submitComment() async {
        guard !state.commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        state.isCommentLoading = true

        do {
            try await estateRepository.createComment(
                estateId: estateId,
                content: state.commentText,
                parentId: state.replyingTo?.comment_id
            )

            // 초기화
            state.commentText = ""
            state.replyingTo = nil

            // 댓글 새로고침
            await loadComments()
        } catch {
            state.errorMessage = "댓글 작성에 실패했습니다."
        }

        state.isCommentLoading = false
    }
}
