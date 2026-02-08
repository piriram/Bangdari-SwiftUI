import Foundation

// MARK: - Payment Validation Request

struct PaymentValidationRequest: Encodable {
    let imp_uid: String
}

// MARK: - Payment Validation Response

struct PaymentValidationResponse: Decodable {
    let payment_id: String
    let order_item: OrderResponse?
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case payment_id, order_item
        case createdAt, updatedAt
        case created_at, updated_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        payment_id = try container.decode(String.self, forKey: .payment_id)
        order_item = try? container.decode(OrderResponse.self, forKey: .order_item)

        if let createdAtValue = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = createdAtValue
        } else {
            createdAt = try container.decodeIfPresent(String.self, forKey: .created_at)
        }

        if let updatedAtValue = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = updatedAtValue
        } else {
            updatedAt = try container.decodeIfPresent(String.self, forKey: .updated_at)
        }
    }
}

// MARK: - Payment Receipt Response

struct PaymentReceiptResponse: Decodable {
    let imp_uid: String
    let merchant_uid: String
    let pay_method: String?
    let channel: String?
    let pg_provider: String?
    let emb_pg_provider: String?
    let pg_tid: String?
    let pg_id: String?
    let escrow: Bool?
    let apply_num: String?

    // 은행 정보
    let bank_code: String?
    let bank_name: String?

    // 카드 정보
    let card_code: String?
    let card_name: String?
    let card_issuer_code: String?
    let card_issuer_name: String?
    let card_publisher_code: String?
    let card_publisher_name: String?
    let card_quota: Int?
    let card_number: String?
    let card_type: Int?

    // 가상계좌 정보
    let vbank_code: String?
    let vbank_name: String?
    let vbank_num: String?
    let vbank_holder: String?
    let vbank_date: Int?
    let vbank_issued_at: Int?

    // 주문 정보
    let name: String?
    let amount: Int
    let currency: String
    let buyer_name: String?
    let buyer_email: String?
    let buyer_tel: String?
    let buyer_addr: String?
    let buyer_postcode: String?
    let custom_data: String?
    let user_agent: String?

    // 상태 및 시간
    let status: String
    let startedAt: String?
    let paidAt: String?
    let receipt_url: String?
    let createdAt: String?
    let updatedAt: String?
}
