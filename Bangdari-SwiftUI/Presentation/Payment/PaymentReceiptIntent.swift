import Foundation
import Combine

// MARK: - Payment Receipt State

struct PaymentReceiptState {
    var receipt: PaymentReceiptResponse?
    var isLoading: Bool = false
    var errorMessage: String?
}

// MARK: - Payment Receipt Intent

@MainActor
final class PaymentReceiptIntent: ObservableObject {
    @Published private(set) var state = PaymentReceiptState()
    private let paymentRepository: PaymentRepository

    init(paymentRepository: PaymentRepository? = nil) {
        self.paymentRepository = paymentRepository ?? DIContainer.shared.makePaymentRepository()
    }

    /// 결제 영수증 조회
    func fetchReceipt(orderCode: String) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let receipt = try await paymentRepository.fetchPaymentReceipt(orderCode: orderCode)
            state.receipt = receipt
        } catch let error as NetworkError {
            state.errorMessage = handleError(error)
        } catch {
            state.errorMessage = "영수증을 불러올 수 없습니다."
        }

        state.isLoading = false
    }

    /// 에러 메시지 처리
    private func handleError(_ error: NetworkError) -> String {
        switch error {
        case .badRequest:
            return "필수값을 채워주세요."
        case .notFound:
            return "주문번호를 다시 확인해주세요."
        case .notParticipant:
            return "주문자 정보가 일치하지 않습니다."
        case .unauthorized:
            return "로그인이 필요합니다."
        default:
            return error.message
        }
    }

    /// 에러 메시지 초기화
    func clearError() {
        state.errorMessage = nil
    }
}
