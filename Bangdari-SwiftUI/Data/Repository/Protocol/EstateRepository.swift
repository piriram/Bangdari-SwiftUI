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
}
