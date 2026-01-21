import Foundation

// MARK: - Remote Estate Repository

final class RemoteEstateRepository: EstateRepository {
    private let network = NetworkService.shared

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
}
