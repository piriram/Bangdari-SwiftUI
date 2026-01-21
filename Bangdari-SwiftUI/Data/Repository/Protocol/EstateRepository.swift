import Foundation

// MARK: - Estate Repository Protocol

protocol EstateRepository {
    func fetchTodayEstates() async throws -> [EstateSummaryResponse]
    func fetchHotEstates() async throws -> [EstateSummaryResponse]
    func fetchTodayTopic() async throws -> [EstateTopic]
    func fetchMainBanners() async throws -> [Banner]
}
