import Foundation

// MARK: - Post Repository Protocol

protocol PostRepository {
    // List
    func fetchPostsByLocation(
        latitude: Double,
        longitude: Double,
        maxDistance: Int,
        category: String?
    ) async throws -> [PostSummaryResponse]

    func searchPosts(
        title: String?,
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse

    func fetchUserPosts(
        userId: String,
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse

    func fetchMyLikedPosts(
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse

    // Detail
    func fetchPostDetail(postId: String) async throws -> PostDetailResponse

    // CRUD
    func createPost(request: PostCreateRequest) async throws -> PostDetailResponse
    func updatePost(postId: String, request: PostCreateRequest) async throws -> PostDetailResponse
    func deletePost(postId: String) async throws

    // File Upload
    func uploadFiles(files: [Data]) async throws -> [String]

    // Like
    func toggleLike(postId: String, like: Bool) async throws -> Bool

    // Comment
    func createComment(postId: String, content: String, parentId: String?) async throws
    func updateComment(postId: String, commentId: String, content: String) async throws
    func deleteComment(postId: String, commentId: String) async throws
}
