import Foundation
import Combine

// MARK: - My Order List State

struct MyOrderListState {
    var orders: [OrderResponse] = []
    var isLoading: Bool = false
    var errorMessage: String?
}

// MARK: - My Order List Intent

@MainActor
final class MyOrderListIntent: ObservableObject {
    @Published private(set) var state = MyOrderListState()
    private let orderRepository: OrderRepository

    init(orderRepository: OrderRepository? = nil) {
        self.orderRepository = orderRepository ?? DIContainer.shared.makeOrderRepository()
    }

    /// 내 주문 목록 조회
    func loadOrders() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let orders = try await orderRepository.fetchMyOrders()
            state.orders = orders
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "주문 목록을 불러올 수 없습니다."
        }

        state.isLoading = false
    }

    /// 에러 메시지 초기화
    func clearError() {
        state.errorMessage = nil
    }
}
