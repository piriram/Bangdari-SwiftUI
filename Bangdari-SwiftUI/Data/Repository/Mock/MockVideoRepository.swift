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
        let sourceFileName = videos.data.first(where: { $0.video_id == videoId })?.file_name ?? "video_1"
        let playbackFileName = mappedPlaybackFileName(from: sourceFileName)

        return try decodeFromJSONObject([
            "video_id": videoId,
            "stream_url": "/data/videos/\(playbackFileName).mp4",
            "qualities": [],
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

    /// Mock 영상 파일명 매핑 (estate_video_* -> 실제 번들 mp4)
    private func mappedPlaybackFileName(from source: String) -> String {
        if source.hasPrefix("video_") {
            return source
        }

        if source.hasPrefix("estate_video_") {
            let suffix = source.replacingOccurrences(of: "estate_video_", with: "")
            if let index = Int(suffix) {
                switch index {
                case 1: return "video_1"
                case 2: return "video_2"
                case 3: return "video_3"
                case 4: return "video_2"
                case 5: return "video_3"
                default: return "video_1"
                }
            }
        }

        return "video_1"
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
