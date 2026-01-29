import Foundation

// MARK: - Estate Repository Protocol

protocol EstateRepository {
    // Home
    func fetchTodayEstates() async throws -> [EstateSummaryResponse]
    func fetchHotEstates() async throws -> [EstateSummaryResponse]
    func fetchTodayTopic() async throws -> [EstateTopic]
    func fetchMainBanners() async throws -> [Banner]

    // List
    func fetchEstatesByLocation(
        latitude: Double,
        longitude: Double,
        maxDistance: Int,
        category: String?
    ) async throws -> [EstateSummaryResponse]

    func fetchMyLikedEstates(
        next: String?,
        limit: Int?,
        category: String?
    ) async throws -> EstatePaginationResponse

    // Detail
    func fetchEstateDetail(estateId: String) async throws -> EstateDetailResponse
    func toggleLike(estateId: String, like: Bool) async throws -> Bool
    func fetchSimilarEstates() async throws -> [EstateSummaryResponse]

    // Comment
    func createComment(estateId: String, content: String, parentId: String?) async throws
    func updateComment(estateId: String, commentId: String, content: String) async throws
    func deleteComment(estateId: String, commentId: String) async throws
}
