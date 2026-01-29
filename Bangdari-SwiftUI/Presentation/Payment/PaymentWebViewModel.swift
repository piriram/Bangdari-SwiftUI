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
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    padding: 20px;
                    text-align: center;
                }
                #status {
                    margin-top: 50px;
                    font-size: 16px;
                    color: #666;
                }
            </style>
            <script src="https://cdn.iamport.kr/v1/iamport.js"></script>
        </head>
        <body>
            <div id="status">결제 페이지를 준비하고 있습니다...</div>
            <script>
                console.log('🔵 포트원 SDK 로드 시작');

                // 페이지 로드 완료 대기
                window.addEventListener('load', function() {
                    console.log('🟢 페이지 로드 완료');

                    if (!window.IMP) {
                        console.error('❌ 포트원 SDK 로드 실패');
                        document.getElementById('status').innerText = '결제 모듈 로드 실패';
                        return;
                    }

                    const IMP = window.IMP;
                    console.log('🟢 포트원 SDK 로드 성공');

                    // 가맹점 식별코드 초기화
                    IMP.init('\(Secrets.impCode)');
                    console.log('🟢 포트원 초기화 완료: \(Secrets.impCode)');

                    document.getElementById('status').innerText = '결제창을 여는 중...';

                    // 결제 요청
                    const paymentData = {
                        pg: 'html5_inicis.INIpayTest',
                        pay_method: 'card',
                        merchant_uid: '\(order.order_code)',
                        name: '\(estateName)',
                        amount: \(order.total_price),
                        buyer_name: '\(buyerName)',
                        buyer_email: '\(buyerEmail)',
                        m_redirect_url: 'http://localhost/payment/complete'
                    };

                    console.log('🔵 결제 요청 데이터:', paymentData);

                    IMP.request_pay(paymentData, function(response) {
                        console.log('🔵 결제 응답:', response);

                        if (response.success) {
                            console.log('✅ 결제 성공:', response.imp_uid);
                            document.getElementById('status').innerText = '결제 성공! 검증 중...';
                            window.webkit.messageHandlers.paymentResult.postMessage({
                                success: true,
                                imp_uid: response.imp_uid
                            });
                        } else {
                            console.log('❌ 결제 실패:', response.error_msg);
                            document.getElementById('status').innerText = '결제 실패: ' + response.error_msg;
                            window.webkit.messageHandlers.paymentResult.postMessage({
                                success: false,
                                error: response.error_msg
                            });
                        }
                    });
                });
            </script>
        </body>
        </html>
        """
    }
}
