import SwiftUI
import WebKit
import iamport_ios
import Then

// MARK: - Payment Web View

struct PaymentWebView: View {
    let order: OrderCreateResponse
    let estateName: String
    let onSuccess: (String) -> Void
    let onCancel: () -> Void
    let onFailure: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            IamportPaymentView(
                payment: createPaymentData(),
                onSuccess: { response in
                    print("✅ 결제 성공: \(response.imp_uid ?? "")")
                    if let impUid = response.imp_uid {
                        onSuccess(impUid)
                    }
                    dismiss()
                },
                onFailed: { response in
                    if let impUid = response?.imp_uid, !impUid.isEmpty {
                        print("⚠️ 실패 콜백이지만 imp_uid 존재, 서버 검증 재시도: \(impUid)")
                        onSuccess(impUid)
                    } else {
                        let message = response?.error_msg ?? "결제가 완료되지 않았습니다."
                        print("❌ 결제 실패: \(message)")
                        onFailure(message)
                    }
                    dismiss()
                }
            )
            .standardNavigationBar(title: "결제")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            NotificationCenter.default.post(name: .paymentFlowDidStart, object: nil)
        }
        .onDisappear {
            NotificationCenter.default.post(name: .paymentFlowDidEnd, object: nil)
        }
    }

    private func createPaymentData() -> IamportPayment {
        IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: order.order_code,
            amount: String(order.total_price)
        ).then {
            $0.pay_method = PayMethod.card.rawValue
            $0.name = estateName
            $0.buyer_name = "홍길동"
            $0.buyer_email = "user@example.com"
            $0.app_scheme = "bangdari://"
        }
    }
}

// MARK: - UIViewRepresentable

struct IamportPaymentView: UIViewRepresentable {
    let payment: IamportPayment
    let onSuccess: (IamportResponse) -> Void
    let onFailed: (IamportResponse?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess, onFailed: onFailed)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .white

        Iamport.shared.paymentWebView(
            webViewMode: webView,
            userCode: Secrets.impCode,
            payment: payment
        ) { response in
            guard let response = response else {
                context.coordinator.onFailed(nil)
                return
            }

            if response.success == true {
                context.coordinator.onSuccess(response)
            } else {
                context.coordinator.onFailed(response)
            }
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 업데이트 불필요
    }

    // MARK: - Coordinator

    final class Coordinator {
        let onSuccess: (IamportResponse) -> Void
        let onFailed: (IamportResponse?) -> Void

        init(onSuccess: @escaping (IamportResponse) -> Void, onFailed: @escaping (IamportResponse?) -> Void) {
            self.onSuccess = onSuccess
            self.onFailed = onFailed
        }
    }
}
