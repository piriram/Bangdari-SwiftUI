import Combine
import Foundation

// MARK: - Post Detail State

struct PostDetailState {
    var post: PostDetailResponse?
    var isLoading: Bool = false
    var isLikeLoading: Bool = false
    var isCommentLoading: Bool = false
    var errorMessage: String?

    // 댓글 입력
    var commentText: String = ""
    var replyingTo: PostComment? = nil

    var isLiked: Bool {
        post?.is_like ?? false
    }

    var likeCount: Int {
        post?.like_count ?? 0
    }
}

// MARK: - Post Detail Intent

@MainActor
final class PostDetailIntent: ObservableObject {
    @Published private(set) var state = PostDetailState()

    private let postRepository: PostRepository
    private let postId: String

    init(postId: String, postRepository: PostRepository? = nil) {
        self.postId = postId
        self.postRepository = postRepository ?? DIContainer.shared.makePostRepository()
    }

    // MARK: - Actions

    func loadDetail() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.post = try await postRepository.fetchPostDetail(postId: postId)
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "게시글을 불러오는 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func toggleLike() async {
        guard let post = state.post else { return }

        state.isLikeLoading = true

        do {
            _ = try await postRepository.toggleLike(postId: postId, like: !post.is_like)
            await loadDetail()
        } catch {
            // 좋아요 실패는 조용히 처리
        }

        state.isLikeLoading = false
    }

    // MARK: - Comment Actions

    func updateCommentText(_ text: String) {
        state.commentText = text
    }

    func setReplyingTo(_ comment: PostComment?) {
        state.replyingTo = comment
    }

    func submitComment() async {
        guard !state.commentText.isEmpty else { return }

        state.isCommentLoading = true

        do {
            try await postRepository.createComment(
                postId: postId,
                content: state.commentText,
                parentId: state.replyingTo?.comment_id
            )
            state.commentText = ""
            state.replyingTo = nil
            await loadDetail()
        } catch {
            // 댓글 작성 실패
        }

        state.isCommentLoading = false
    }

    func deleteComment(_ commentId: String) async {
        do {
            try await postRepository.deleteComment(postId: postId, commentId: commentId)
            await loadDetail()
        } catch {
            // 삭제 실패
        }
    }
}
