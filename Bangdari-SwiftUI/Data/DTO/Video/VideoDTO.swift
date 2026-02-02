import Foundation

// MARK: - Video Response

struct VideoResponse: Decodable, Identifiable, Equatable {
    let video_id: String
    let file_name: String
    let title: String
    let description: String
    let duration: Double
    let thumbnail_url: String
    let available_qualities: [String]
    let view_count: Int
    let like_count: Int
    let is_liked: Bool
    let createdAt: String

    var id: String { video_id }

    private enum CodingKeys: String, CodingKey {
        case video_id, file_name, title, description, duration
        case thumbnail_url, available_qualities, view_count
        case like_count, is_liked, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        video_id = try container.decode(String.self, forKey: .video_id)
        file_name = try container.decode(String.self, forKey: .file_name)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        duration = try container.decode(Double.self, forKey: .duration)
        thumbnail_url = try container.decode(String.self, forKey: .thumbnail_url)
        available_qualities = try container.decodeIfPresent([String].self, forKey: .available_qualities) ?? []
        view_count = try container.decodeIfPresent(Int.self, forKey: .view_count) ?? 0
        like_count = try container.decodeIfPresent(Int.self, forKey: .like_count) ?? 0
        is_liked = try container.decodeIfPresent(Bool.self, forKey: .is_liked) ?? false
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }

    static func == (lhs: VideoResponse, rhs: VideoResponse) -> Bool {
        lhs.video_id == rhs.video_id
    }
}

// MARK: - Video Pagination Response

struct VideoPaginationResponse: Decodable {
    let data: [VideoResponse]
    let next_cursor: String?

    var hasMore: Bool {
        guard let cursor = next_cursor else { return false }
        return !cursor.isEmpty && cursor != "0"
    }
}

// MARK: - Video Stream Response

struct VideoStreamResponse: Decodable {
    let video_id: String
    let stream_url: String
    let qualities: [StreamQuality]
    let subtitles: [Subtitle]

    private enum CodingKeys: String, CodingKey {
        case video_id, stream_url, qualities, subtitles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        video_id = try container.decode(String.self, forKey: .video_id)
        stream_url = try container.decode(String.self, forKey: .stream_url)
        qualities = try container.decodeIfPresent([StreamQuality].self, forKey: .qualities) ?? []
        subtitles = try container.decodeIfPresent([Subtitle].self, forKey: .subtitles) ?? []
    }
}

// MARK: - Stream Quality

struct StreamQuality: Decodable, Identifiable {
    let quality: String
    let url: String

    var id: String { quality }
}

// MARK: - Subtitle

struct Subtitle: Decodable, Identifiable {
    let language: String
    let name: String
    let is_default: Bool
    let url: String

    var id: String { language }

    private enum CodingKeys: String, CodingKey {
        case language, name, is_default, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decode(String.self, forKey: .language)
        name = try container.decode(String.self, forKey: .name)
        is_default = try container.decodeIfPresent(Bool.self, forKey: .is_default) ?? false
        url = try container.decode(String.self, forKey: .url)
    }
}

// MARK: - Video Like Request/Response

struct VideoLikeRequest: Encodable {
    let like_status: Bool
}

struct VideoLikeResponse: Decodable {
    let like_status: Bool
}
