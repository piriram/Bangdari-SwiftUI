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

    private enum CodingKeys: String, CodingKey {
        case estate_id
        case category
        case title
        case deposit
        case monthly_rent
        case area
        case geolocation
        case files
        case distance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        estate_id = try container.decode(String.self, forKey: .estate_id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        deposit = try container.decode(Int.self, forKey: .deposit)
        monthly_rent = try container.decode(Int.self, forKey: .monthly_rent)
        area = try container.decode(Double.self, forKey: .area)
        geolocation = try container.decode(Geolocation.self, forKey: .geolocation)
        files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
    }
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

// MARK: - Estate Pagination Response (cursor 기반)

struct EstatePaginationResponse: Decodable {
    let data: [EstateSummaryResponse]
    let next_cursor: String

    var hasMore: Bool {
        next_cursor != "0"
    }
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

    private enum CodingKeys: String, CodingKey {
        case banner_id
        case id
        case title
        case image
        case link
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let bannerId = try container.decodeIfPresent(String.self, forKey: .banner_id) {
            banner_id = bannerId
        } else if let id = try container.decodeIfPresent(String.self, forKey: .id) {
            banner_id = id
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.banner_id,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing banner_id or id"
                )
            )
        }
        title = try container.decode(String.self, forKey: .title)
        image = try container.decode(String.self, forKey: .image)
        link = try container.decodeIfPresent(String.self, forKey: .link)
    }
}
