import Foundation

// MARK: - Mock Post Repository

final class MockPostRepository: PostRepository {

    // MARK: - List

    func fetchPostsByLocation(
        latitude: Double,
        longitude: Double,
        maxDistance: Int,
        category: String?
    ) async throws -> [PostSummaryResponse] {
        let response: PostPaginationResponse = try loadJSON(filename: "posts")

        if let category, !category.isEmpty {
            return response.data.filter { $0.category == category }
        }

        return response.data
    }

    func searchPosts(
        title: String?,
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse {
        let response: PostPaginationResponse = try loadJSON(filename: "posts")
        let keyword = title?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        let filtered = keyword.isEmpty
            ? response.data
            : response.data.filter {
                $0.title.lowercased().contains(keyword) || $0.content.lowercased().contains(keyword)
            }

        // Mock는 단일 페이지로 처리
        return try decodeFromJSONObject([
            "data": filtered.map(postSummaryDictionary),
            "next_cursor": "0"
        ])
    }

    func fetchUserPosts(
        userId: String,
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse {
        let response: PostPaginationResponse = try loadJSON(filename: "posts")
        let filtered = response.data.filter { $0.creator.user_id == userId }

        return try decodeFromJSONObject([
            "data": filtered.map(postSummaryDictionary),
            "next_cursor": "0"
        ])
    }

    func fetchMyLikedPosts(
        next: String?,
        limit: Int?
    ) async throws -> PostPaginationResponse {
        let response: PostPaginationResponse = try loadJSON(filename: "posts")
        let filtered = response.data.filter(\.is_like)

        return try decodeFromJSONObject([
            "data": filtered.map(postSummaryDictionary),
            "next_cursor": "0"
        ])
    }

    // MARK: - Detail

    func fetchPostDetail(postId: String) async throws -> PostDetailResponse {
        let list: PostPaginationResponse = try loadJSON(filename: "posts")

        if let matched = list.data.first(where: { $0.post_id == postId }) {
            return try decodeFromJSONObject(postDetailDictionary(from: matched))
        }

        let fallback: PostDetailResponse = try loadJSON(filename: "post-detail")
        return fallback
    }

    // MARK: - CRUD

    func createPost(request: PostCreateRequest) async throws -> PostDetailResponse {
        let now = ISO8601DateFormatter().string(from: Date())
        let newPostId = "mock-post-\(Int(Date().timeIntervalSince1970))"

        return try decodeFromJSONObject([
            "post_id": newPostId,
            "category": request.category,
            "title": request.title,
            "content": request.content,
            "geolocation": [
                "longitude": request.longitude,
                "latitude": request.latitude
            ],
            "creator": [
                "user_id": "mock_user_123",
                "nick": "목업유저",
                "introduction": "",
                "profileImage": NSNull()
            ],
            "files": request.files ?? [],
            "is_like": false,
            "like_count": 0,
            "comments": [],
            "createdAt": now,
            "updatedAt": now
        ])
    }

    func updatePost(postId: String, request: PostCreateRequest) async throws -> PostDetailResponse {
        let now = ISO8601DateFormatter().string(from: Date())

        return try decodeFromJSONObject([
            "post_id": postId,
            "category": request.category,
            "title": request.title,
            "content": request.content,
            "geolocation": [
                "longitude": request.longitude,
                "latitude": request.latitude
            ],
            "creator": [
                "user_id": "mock_user_123",
                "nick": "목업유저",
                "introduction": "",
                "profileImage": NSNull()
            ],
            "files": request.files ?? [],
            "is_like": false,
            "like_count": 0,
            "comments": [],
            "createdAt": now,
            "updatedAt": now
        ])
    }

    func deletePost(postId: String) async throws {
        // Mock: no-op
    }

    // MARK: - File Upload

    func uploadFiles(files: [Data]) async throws -> [String] {
        guard !files.isEmpty else { return [] }

        return files.enumerated().map { index, _ in
            "/data/posts/post_\((index % 11) + 1).jpg"
        }
    }

    // MARK: - Like

    func toggleLike(postId: String, like: Bool) async throws -> Bool {
        like
    }

    // MARK: - Comment

    func createComment(postId: String, content: String, parentId: String?) async throws {
        // Mock: no-op
    }

    func updateComment(postId: String, commentId: String, content: String) async throws {
        // Mock: no-op
    }

    func deleteComment(postId: String, commentId: String) async throws {
        // Mock: no-op
    }

    // MARK: - Helpers

    private func loadJSON<T: Decodable>(filename: String) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw MockPostError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private func decodeFromJSONObject<T: Decodable>(_ object: Any) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func postSummaryDictionary(_ post: PostSummaryResponse) -> [String: Any] {
        [
            "post_id": post.post_id,
            "category": post.category,
            "title": post.title,
            "content": post.content,
            "geolocation": [
                "longitude": post.geolocation.longitude,
                "latitude": post.geolocation.latitude
            ],
            "creator": [
                "user_id": post.creator.user_id,
                "nick": post.creator.nick,
                "introduction": post.creator.introduction ?? "",
                "profileImage": post.creator.profileImage ?? ""
            ],
            "files": post.files,
            "is_like": post.is_like,
            "like_count": post.like_count,
            "createdAt": post.createdAt,
            "updatedAt": post.updatedAt
        ]
    }

    private func postDetailDictionary(from post: PostSummaryResponse) -> [String: Any] {
        var dict = postSummaryDictionary(post)
        dict["comments"] = []
        return dict
    }
}

private enum MockPostError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Mock Post 데이터 파일을 찾을 수 없습니다: \(filename).json"
        }
    }
}
