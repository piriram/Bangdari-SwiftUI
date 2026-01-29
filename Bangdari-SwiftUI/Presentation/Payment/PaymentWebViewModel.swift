import Foundation
import Combine

// MARK: - Payment Web View Model

@MainActor
final class PaymentWebViewModel: ObservableObject {
    private let order: OrderCreateResponse
    private let estateName: String
    private let buyerName: String
    private let buyerEmail: String

    init(
        order: OrderCreateResponse,
        estateName: String,
        buyerName: String = "홍길동",
        buyerEmail: String = "user@example.com"
    ) {
        self.order = order
        self.estateName = estateName
        self.buyerName = buyerName
        self.buyerEmail = buyerEmail
    }

    /// 포트원 결제 HTML 생성
    var htmlContent: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>결제</title>
            <script src="https://cdn.iamport.kr/v1/iamport.js"></script>
        </head>
        <body>
            <script>
                const IMP = window.IMP;
                IMP.init('\(Secrets.impCode)');

                IMP.request_pay({
                    pg: 'html5_inicis.INIpayTest',
                    pay_method: 'card',
                    merchant_uid: '\(order.order_code)',
                    name: '\(estateName)',
                    amount: \(order.total_price),
                    buyer_name: '\(buyerName)',
                    buyer_email: '\(buyerEmail)',
                }, function(response) {
                    if (response.success) {
                        // 결제 성공
                        window.webkit.messageHandlers.paymentResult.postMessage({
                            success: true,
                            imp_uid: response.imp_uid
                        });
                    } else {
                        // 결제 실패
                        window.webkit.messageHandlers.paymentResult.postMessage({
                            success: false,
                            error: response.error_msg
                        });
                    }
                });
            </script>
        </body>
        </html>
        """
    }
}
