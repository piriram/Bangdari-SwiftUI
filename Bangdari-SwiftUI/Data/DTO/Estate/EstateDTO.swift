import Foundation

// MARK: - Estate Summary (리스트용)

struct EstateSummaryResponse: Decodable {
    let estate_id: String
    let category: String
    let title: String
    let deposit: Int
    let monthly_rent: Int
    let area: Double
    let geolocation: Geolocation
    let files: [String]
    let distance: Double?
}

// MARK: - Geolocation

struct Geolocation: Decodable {
    let longitude: Double
    let latitude: Double
}

// MARK: - Estate List Response

struct EstateListResponse: Decodable {
    let data: [EstateSummaryResponse]
}

// MARK: - Estate Topic

struct EstateTopic: Decodable {
    let title: String
    let content: String
    let date: String
    let link: String
}

struct EstateTopicResponse: Decodable {
    let data: [EstateTopic]
}

// MARK: - Banner

struct BannerResponse: Decodable {
    let data: [Banner]
}

struct Banner: Decodable {
    let banner_id: String
    let title: String
    let image: String
    let link: String?
}
