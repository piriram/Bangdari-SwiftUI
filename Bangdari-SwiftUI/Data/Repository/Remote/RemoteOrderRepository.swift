import Foundation

// MARK: - Remote Order Repository

final class RemoteOrderRepository: OrderRepository {
    private let network = NetworkService.shared

    func createOrder(estateId: String, totalPrice: Int) async throws -> OrderCreateResponse {
        let body = CreateOrderRequest(estate_id: estateId, total_price: totalPrice)
        return try await network.request(.createOrder, body: body, type: OrderCreateResponse.self)
    }

    func fetchMyOrders() async throws -> [OrderResponse] {
        let response = try await network.request(.orders, type: OrderListResponse.self)
        return response.data
    }
}
