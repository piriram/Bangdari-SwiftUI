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
    let geolocation: Geolocation
}

// MARK: - Order List Response

struct OrderListResponse: Decodable {
    let data: [OrderResponse]
}
