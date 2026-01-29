import Foundation

// MARK: - Payment Repository Protocol

protocol PaymentRepository {
    /// 결제 영수증 검증 (포트원 imp_uid로 검증)
    func validatePayment(impUid: String) async throws -> PaymentValidationResponse

    /// 결제 영수증 조회
    func fetchPaymentReceipt(orderCode: String) async throws -> PaymentReceiptResponse
}
