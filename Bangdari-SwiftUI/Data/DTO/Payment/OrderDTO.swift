import Foundation

// MARK: - Create Order Request

struct CreateOrderRequest: Encodable {
    let estate_id: String
    let total_price: Int
}

// MARK: - Order Create Response

struct OrderCreateResponse: Decodable {
    let order_id: String
    let order_code: String
    let total_price: Int
    let createdAt: String
    let updatedAt: String
}

// MARK: - Order Response

struct OrderResponse: Decodable, Identifiable {
    let order_id: String
    let order_code: String
    let paidAt: String
    let createdAt: String
    let updatedAt: String
    let estate: EstateSummaryForOrder

    var id: String { order_id }
}

// MARK: - Estate Summary for Order

struct EstateSummaryForOrder: Decodable {
    let id: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Int
    let monthly_rent: Int
    let built_year: String
    let area: Double
    let floors: Int
    let geolocation: Geolocation
    let created_at: String
    let updated_at: String

    private enum CodingKeys: String, CodingKey {
        case id, category, title, introduction, thumbnails
        case deposit, monthly_rent, built_year, area, floors
        case geolocation
        case created_at, createdAt
        case updated_at, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decode(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        introduction = try container.decodeIfPresent(String.self, forKey: .introduction) ?? ""
        thumbnails = try container.decodeIfPresent([String].self, forKey: .thumbnails) ?? []
        deposit = try container.decodeIfPresent(Int.self, forKey: .deposit) ?? 0
        monthly_rent = try container.decodeIfPresent(Int.self, forKey: .monthly_rent) ?? 0
        built_year = try container.decodeIfPresent(String.self, forKey: .built_year) ?? ""
        area = try container.decodeIfPresent(Double.self, forKey: .area) ?? 0
        floors = try container.decodeIfPresent(Int.self, forKey: .floors) ?? 0
        geolocation = try container.decode(Geolocation.self, forKey: .geolocation)

        if let createdAtValue = try container.decodeIfPresent(String.self, forKey: .created_at) {
            created_at = createdAtValue
        } else {
            created_at = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        }

        if let updatedAtValue = try container.decodeIfPresent(String.self, forKey: .updated_at) {
            updated_at = updatedAtValue
        } else {
            updated_at = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        }
    }
}

// MARK: - Order List Response

struct OrderListResponse: Decodable {
    let data: [OrderResponse]
}
