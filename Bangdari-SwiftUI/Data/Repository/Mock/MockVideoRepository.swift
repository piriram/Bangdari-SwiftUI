import Foundation

// MARK: - Mock Video Repository

final class MockVideoRepository: VideoRepository {

    func fetchVideos(next: String?, limit: Int?) async throws -> VideoPaginationResponse {
        let response: VideoPaginationResponse = try loadJSON(filename: "videos")

        let cappedData: [VideoResponse]
        if let limit, limit > 0 {
            cappedData = Array(response.data.prefix(limit))
        } else {
            cappedData = response.data
        }

        return try decodeFromJSONObject([
            "data": cappedData.map(videoDictionary),
            "next_cursor": "0"
        ])
    }

    func fetchStreamURL(videoId: String) async throws -> VideoStreamResponse {
        let videos: VideoPaginationResponse = try loadJSON(filename: "videos")
        let fileName = videos.data.first(where: { $0.video_id == videoId })?.file_name ?? "video_1"

        return try decodeFromJSONObject([
            "video_id": videoId,
            "stream_url": "/data/videos/\(fileName)/master.m3u8",
            "qualities": [
                ["quality": "720p", "url": "/data/videos/\(fileName)/720p.m3u8"],
                ["quality": "1080p", "url": "/data/videos/\(fileName)/1080p.m3u8"],
                ["quality": "480p", "url": "/data/videos/\(fileName)/480p.m3u8"]
            ],
            "subtitles": []
        ])
    }

    func toggleLike(videoId: String, likeStatus: Bool) async throws -> VideoLikeResponse {
        try decodeFromJSONObject([
            "like_status": likeStatus
        ])
    }

    // MARK: - Helpers

    private func loadJSON<T: Decodable>(filename: String) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw MockVideoError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func decodeFromJSONObject<T: Decodable>(_ object: Any) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func videoDictionary(_ video: VideoResponse) -> [String: Any] {
        [
            "video_id": video.video_id,
            "file_name": video.file_name,
            "title": video.title,
            "description": video.description,
            "duration": video.duration,
            "thumbnail_url": video.thumbnail_url,
            "available_qualities": video.available_qualities,
            "view_count": video.view_count,
            "like_count": video.like_count,
            "is_liked": video.is_liked,
            "createdAt": video.createdAt
        ]
    }
}

private enum MockVideoError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Mock Video 데이터 파일을 찾을 수 없습니다: \(filename).json"
        }
    }
}
