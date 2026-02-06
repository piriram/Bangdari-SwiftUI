import Foundation

// MARK: - Remote Video Repository

final class RemoteVideoRepository: VideoRepository {
    private let networkService = NetworkService.shared

    func fetchVideos(next: String?, limit: Int?) async throws -> VideoPaginationResponse {
        let endpoint = APIEndpoint.videos(next: next, limit: limit)
        return try await networkService.request(endpoint, type: VideoPaginationResponse.self)
    }

    func fetchStreamURL(videoId: String) async throws -> VideoStreamResponse {
        let endpoint = APIEndpoint.videoStream(videoId: videoId)
        return try await networkService.request(endpoint, type: VideoStreamResponse.self)
    }

    func toggleLike(videoId: String, likeStatus: Bool) async throws -> VideoLikeResponse {
        let endpoint = APIEndpoint.videoLike(videoId: videoId)
        let request = VideoLikeRequest(like_status: likeStatus)
        return try await networkService.request(endpoint, body: request, type: VideoLikeResponse.self)
    }
}
