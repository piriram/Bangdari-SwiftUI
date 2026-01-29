import Foundation

// MARK: - Remote Estate Repository

final class RemoteEstateRepository: EstateRepository {
    private let network = NetworkService.shared

    // MARK: - Home

    func fetchTodayEstates() async throws -> [EstateSummaryResponse] {
        let response = try await network.request(.todayEstates, type: EstateListResponse.self)
        return response.data
    }

    func fetchHotEstates() async throws -> [EstateSummaryResponse] {
        let response = try await network.request(.hotEstates, type: EstateListResponse.self)
        return response.data
    }

    func fetchTodayTopic() async throws -> [EstateTopic] {
        let response = try await network.request(.todayTopic, type: EstateTopicResponse.self)
        return response.data
    }

    func fetchMainBanners() async throws -> [Banner] {
        let response = try await network.request(.mainBanners, type: BannerResponse.self)
        return response.data
    }

    // MARK: - List

    func fetchEstatesByLocation(
        latitude: Double,
        longitude: Double,
        maxDistance: Int,
        category: String?
    ) async throws -> [EstateSummaryResponse] {
        let endpoint = APIEndpoint.estatesGeolocation(
            lat: latitude,
            lng: longitude,
            maxDistance: maxDistance,
            category: category
        )
        let response = try await network.request(endpoint, type: EstateListResponse.self)
        return response.data
    }

    func fetchMyLikedEstates(
        next: String?,
        limit: Int?,
        category: String?
    ) async throws -> EstatePaginationResponse {
        let endpoint = APIEndpoint.myLikedEstates(next: next, limit: limit, category: category)
        return try await network.request(endpoint, type: EstatePaginationResponse.self)
    }

    // MARK: - Detail

    func fetchEstateDetail(estateId: String) async throws -> EstateDetailResponse {
        let endpoint = APIEndpoint.estateDetail(estateId: estateId)
        return try await network.request(endpoint, type: EstateDetailResponse.self)
    }

    func toggleLike(estateId: String, like: Bool) async throws -> Bool {
        let endpoint = APIEndpoint.estateLike(estateId: estateId)
        let body = EstateLikeRequest(like_status: like)
        let response = try await network.request(endpoint, body: body, type: EstateLikeResponse.self)
        return response.like_status
    }

    func fetchSimilarEstates() async throws -> [EstateSummaryResponse] {
        let response = try await network.request(.similarEstates, type: EstateListResponse.self)
        return response.data
    }

    // MARK: - Comment

    func createComment(estateId: String, content: String, parentId: String?) async throws {
        let endpoint = APIEndpoint.createEstateComment(estateId: estateId)
        let body = EstateCommentRequest(content: content, parentId: parentId)
        _ = try await network.request(endpoint, body: body, type: EstateComment.self)
    }

    func updateComment(estateId: String, commentId: String, content: String) async throws {
        let endpoint = APIEndpoint.updateEstateComment(estateId: estateId, commentId: commentId)
        let body = ["content": content]
        _ = try await network.request(endpoint, body: body, type: EstateComment.self)
    }

    func deleteComment(estateId: String, commentId: String) async throws {
        let endpoint = APIEndpoint.deleteEstateComment(estateId: estateId, commentId: commentId)
        try await network.requestWithoutResponse(endpoint)
    }
}
