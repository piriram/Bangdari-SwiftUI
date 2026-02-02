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
        case geolocation, created_at, updated_at
    }
}

// MARK: - Order List Response

struct OrderListResponse: Decodable {
    let data: [OrderResponse]
}
