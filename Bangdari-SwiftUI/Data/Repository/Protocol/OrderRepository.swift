import Foundation

// MARK: - Order Repository Protocol

protocol OrderRepository {
    /// 주문 생성
    func createOrder(estateId: String, totalPrice: Int) async throws -> OrderCreateResponse

    /// 내 주문 내역 조회 (결제 완료된 주문만)
    func fetchMyOrders() async throws -> [OrderResponse]
}
