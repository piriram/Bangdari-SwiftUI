import Foundation

// MARK: - Remote Payment Repository

final class RemotePaymentRepository: PaymentRepository {
    private let network = NetworkService.shared

    func validatePayment(impUid: String) async throws -> PaymentValidationResponse {
        let body = PaymentValidationRequest(imp_uid: impUid)
        return try await network.request(.validatePayment, body: body, type: PaymentValidationResponse.self)
    }

    func fetchPaymentReceipt(orderCode: String) async throws -> PaymentReceiptResponse {
        let endpoint = APIEndpoint.paymentReceipt(orderCode: orderCode)
        return try await network.request(endpoint, type: PaymentReceiptResponse.self)
    }
}
