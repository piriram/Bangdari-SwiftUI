import Foundation

// MARK: - Video Repository Protocol

protocol VideoRepository {
    func fetchVideos(next: String?, limit: Int?) async throws -> VideoPaginationResponse
    func fetchStreamURL(videoId: String) async throws -> VideoStreamResponse
    func toggleLike(videoId: String, likeStatus: Bool) async throws -> VideoLikeResponse
}
