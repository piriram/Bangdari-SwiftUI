import Foundation

// MARK: - Payment Validation Request

struct PaymentValidationRequest: Encodable {
    let imp_uid: String
}

// MARK: - Payment Validation Response

struct PaymentValidationResponse: Decodable {
    let payment_id: String
    let order_item: OrderResponse
    let createdAt: String
    let updatedAt: String
}

// MARK: - Payment Receipt Response

struct PaymentReceiptResponse: Decodable {
    let imp_uid: String
    let merchant_uid: String
    let status: String
    let amount: Double
    let currency: String
    let pg_provider: String
    let pg_tid: String
    let pay_method: String
    let buyer_name: String
    let buyer_email: String
    let buyer_tel: String
    let startedAt: String
    let paidAt: String
    let createdAt: String
    let updatedAt: String
    let receipt_url: String
}
