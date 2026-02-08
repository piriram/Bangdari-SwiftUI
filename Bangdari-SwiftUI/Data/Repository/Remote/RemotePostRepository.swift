import Foundation

// MARK: - Remote Post Repository

final class RemotePostRepository: PostRepository {
    private let network = NetworkService.shared

    // MARK: - List

    func fetchPostsByLocation(
        latitude: Double,
        longitude: Double,
        maxDistance: Int,
        category: String?
    ) async throws -> [PostSummaryResponse] {
        let endpoint = APIEndpoint.postsGeolocation(
            lat: latitude,
            lng: longitude,
            maxDistance: maxDistance,
            category: category
        )
        let response = try await network.request(endpoint, type: PostListResponse.self)
        return response.data
    }

    func searchPosts(
        title: String?,
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse {
        let endpoint = APIEndpoint.searchPosts(title: title, next: next, limit: limit)
        return try await network.request(endpoint, type: PostPaginationResponse.self)
    }

    func fetchUserPosts(
        userId: String,
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse {
        let endpoint = APIEndpoint.userPosts(userId: userId, next: next, limit: limit)
        return try await network.request(endpoint, type: PostPaginationResponse.self)
    }

    func fetchMyLikedPosts(
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse {
        let endpoint = APIEndpoint.myLikedPosts(next: next, limit: limit)
        return try await network.request(endpoint, type: PostPaginationResponse.self)
    }

    // MARK: - Detail

    func fetchPostDetail(postId: String) async throws -> PostDetailResponse {
        let endpoint = APIEndpoint.postDetail(postId: postId)
        return try await network.request(endpoint, type: PostDetailResponse.self)
    }

    // MARK: - File Upload

    func uploadFiles(files: [Data]) async throws -> [String] {
        let response = try await network.uploadFiles(
            .uploadPostFiles,
            files: files,
            fieldName: "files",
            type: PostFileResponse.self
        )
        return response.files
    }

    // MARK: - CRUD

    func createPost(request: PostCreateRequest) async throws -> PostDetailResponse {
        return try await network.request(.createPost, body: request, type: PostDetailResponse.self)
    }

    func updatePost(postId: String, request: PostCreateRequest) async throws -> PostDetailResponse {
        let endpoint = APIEndpoint.updatePost(postId: postId)
        return try await network.request(endpoint, body: request, type: PostDetailResponse.self)
    }

    func deletePost(postId: String) async throws {
        let endpoint = APIEndpoint.deletePost(postId: postId)
        _ = try await network.requestWithoutResponse(endpoint)
    }

    // MARK: - Like

    func toggleLike(postId: String, like: Bool) async throws -> Bool {
        let endpoint = APIEndpoint.postLike(postId: postId)
        let body = PostLikeRequest(like_status: like)
        let response = try await network.request(endpoint, body: body, type: PostLikeResponse.self)
        return response.like_status
    }

    // MARK: - Comment

    func createComment(postId: String, content: String, parentId: String?) async throws {
        let endpoint = APIEndpoint.createPostComment(postId: postId)
        let body = PostCommentRequest(content: content, parentId: parentId)
        _ = try await network.request(endpoint, body: body, type: PostComment.self)
    }

    func updateComment(postId: String, commentId: String, content: String) async throws {
        let endpoint = APIEndpoint.updatePostComment(postId: postId, commentId: commentId)
        let body = ["content": content]
        _ = try await network.request(endpoint, body: body, type: PostComment.self)
    }

    func deleteComment(postId: String, commentId: String) async throws {
        let endpoint = APIEndpoint.deletePostComment(postId: postId, commentId: commentId)
        _ = try await network.requestWithoutResponse(endpoint)
    }
}
