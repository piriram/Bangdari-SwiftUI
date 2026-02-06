import SwiftUI

// MARK: - Payment Receipt View

struct PaymentReceiptView: View {
    let orderCode: String

    @StateObject private var intent = PaymentReceiptIntent()
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            if intent.state.isLoading {
                ProgressView("영수증을 불러오는 중...")
            } else if let receipt = intent.state.receipt {
                receiptDetailView(receipt)
            } else {
                emptyView
            }
        }
        .standardNavigationBar(title: "결제 영수증")
        .task {
            await intent.fetchReceipt(orderCode: orderCode)
        }
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {
                intent.clearError()
            }
        } message: {
            Text(intent.state.errorMessage ?? "")
        }
        .onChange(of: intent.state.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            Text("영수증을 불러올 수 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Receipt Detail View

    @ViewBuilder
    private func receiptDetailView(_ receipt: PaymentReceiptResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)

                    Text("결제 완료")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(formattedAmount(receipt.amount))
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundStyle(.primary)
                }
                .padding(.top, 20)

                // 결제 정보
                VStack(spacing: 16) {
                    sectionHeader("결제 정보")

                    infoRow(label: "결제 수단", value: paymentMethod(receipt))

                    if let cardNumber = receipt.card_number {
                        infoRow(label: "카드 번호", value: cardNumber)
                    }

                    if let cardQuota = receipt.card_quota {
                        let quotaText = cardQuota == 0 ? "일시불" : "\(cardQuota)개월"
                        infoRow(label: "할부", value: quotaText)
                    }

                    if let paidAt = receipt.paidAt {
                        infoRow(label: "결제 시각", value: formattedDate(paidAt))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 주문자 정보
                VStack(spacing: 16) {
                    sectionHeader("주문자 정보")

                    if let buyerName = receipt.buyer_name {
                        infoRow(label: "이름", value: buyerName)
                    }

                    if let buyerTel = receipt.buyer_tel {
                        infoRow(label: "연락처", value: buyerTel)
                    }

                    if let buyerEmail = receipt.buyer_email {
                        infoRow(label: "이메일", value: buyerEmail)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 거래 정보
                VStack(spacing: 16) {
                    sectionHeader("거래 정보")

                    infoRow(label: "주문번호", value: receipt.merchant_uid)
                    infoRow(label: "거래번호", value: receipt.imp_uid)

                    if let pgTid = receipt.pg_tid {
                        infoRow(label: "PG 거래번호", value: pgTid)
                    }

                    if let applyNum = receipt.apply_num {
                        infoRow(label: "승인번호", value: applyNum)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // 매출전표 버튼
                if let receiptURL = receipt.receipt_url,
                   let url = URL(string: receiptURL) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("매출전표 보기")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    // MARK: - Helper Methods

    private func formattedAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") + "원"
    }

    private func paymentMethod(_ receipt: PaymentReceiptResponse) -> String {
        if let cardName = receipt.card_name {
            return cardName
        } else if let payMethod = receipt.pay_method {
            switch payMethod {
            case "card": return "신용카드"
            case "trans": return "실시간계좌이체"
            case "vbank": return "가상계좌"
            case "phone": return "휴대폰"
            default: return payMethod
            }
        } else {
            return "알 수 없음"
        }
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .long
        displayFormatter.timeStyle = .medium
        displayFormatter.locale = Locale(identifier: "ko_KR")
        return displayFormatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        PaymentReceiptView(orderCode: "ORDER_1234567890")
    }
}
