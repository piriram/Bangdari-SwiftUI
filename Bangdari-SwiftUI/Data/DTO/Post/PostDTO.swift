import Foundation

// MARK: - Post Summary (리스트용)

struct PostSummaryResponse: Decodable, Identifiable, Equatable {
    let post_id: String
    let category: String
    let title: String
    let content: String
    let geolocation: Geolocation
    let creator: UserInfo
    let files: [String]
    let is_like: Bool
    let like_count: Int
    let createdAt: String
    let updatedAt: String

    var id: String { post_id }

    private enum CodingKeys: String, CodingKey {
        case post_id, category, title, content, geolocation
        case creator, files, is_like, like_count, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        post_id = try container.decode(String.self, forKey: .post_id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        geolocation = try container.decode(Geolocation.self, forKey: .geolocation)
        creator = try container.decode(UserInfo.self, forKey: .creator)
        files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
        is_like = try container.decodeIfPresent(Bool.self, forKey: .is_like) ?? false
        like_count = try container.decodeIfPresent(Int.self, forKey: .like_count) ?? 0
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }

    static func == (lhs: PostSummaryResponse, rhs: PostSummaryResponse) -> Bool {
        lhs.post_id == rhs.post_id
    }
}

// MARK: - Post Detail Response

struct PostDetailResponse: Decodable {
    let post_id: String
    let category: String
    let title: String
    let content: String
    let geolocation: Geolocation
    let creator: UserInfo
    let files: [String]
    let is_like: Bool
    let like_count: Int
    let comments: [PostComment]
    let createdAt: String
    let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case post_id, category, title, content, geolocation
        case creator, files, is_like, like_count, comments, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        post_id = try container.decode(String.self, forKey: .post_id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        geolocation = try container.decode(Geolocation.self, forKey: .geolocation)
        creator = try container.decode(UserInfo.self, forKey: .creator)
        files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
        is_like = try container.decodeIfPresent(Bool.self, forKey: .is_like) ?? false
        like_count = try container.decodeIfPresent(Int.self, forKey: .like_count) ?? 0
        comments = try container.decodeIfPresent([PostComment].self, forKey: .comments) ?? []
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

// MARK: - Post Comment

struct PostComment: Decodable, Identifiable {
    let comment_id: String
    let content: String
    let creator: UserInfo
    let createdAt: String
    let replies: [PostComment]?

    var id: String { comment_id }
}

// MARK: - Post List Response

struct PostListResponse: Decodable {
    let data: [PostSummaryResponse]
}

// MARK: - Post Pagination Response

struct PostPaginationResponse: Decodable {
    let data: [PostSummaryResponse]
    let next_cursor: String

    var hasMore: Bool {
        next_cursor != "0"
    }
}

// MARK: - Post Create/Update Request

struct PostCreateRequest: Encodable {
    let category: String
    let title: String
    let content: String
    let longitude: Double
    let latitude: Double
    let files: [String]?
}

// MARK: - Post Like Request/Response

struct PostLikeRequest: Encodable {
    let like_status: Bool
}

struct PostLikeResponse: Decodable {
    let like_status: Bool
}

// MARK: - Post File Upload Response

struct PostFileResponse: Decodable {
    let files: [String]
}

// MARK: - Post Comment Request

struct PostCommentRequest: Encodable {
    let content: String
    let parent_comment_id: String?

    init(content: String, parentId: String? = nil) {
        self.content = content
        self.parent_comment_id = parentId
    }
}
