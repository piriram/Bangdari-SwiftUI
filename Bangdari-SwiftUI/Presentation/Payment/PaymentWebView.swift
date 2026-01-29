import SwiftUI
import WebKit

// MARK: - Payment Web View

struct PaymentWebView: View {
    @StateObject private var viewModel: PaymentWebViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    let onSuccess: (String) -> Void
    let onCancel: () -> Void

    init(
        order: OrderCreateResponse,
        estateName: String,
        onSuccess: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: PaymentWebViewModel(
            order: order,
            estateName: estateName
        ))
        self.onSuccess = onSuccess
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationView {
            ZStack {
                WebViewRepresentable(
                    htmlContent: viewModel.htmlContent,
                    onResult: handlePaymentResult,
                    onLoadingChange: { isLoading = $0 }
                )

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("결제 페이지를 불러오는 중...")
                            .font(.pretendard(.body2))
                            .foregroundColor(.gray60)
                    }
                }
            }
            .navigationTitle("결제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
    }

    private func handlePaymentResult(_ result: [String: Any]) {
        if let success = result["success"] as? Bool {
            if success, let impUid = result["imp_uid"] as? String {
                onSuccess(impUid)
                dismiss()
            } else if let error = result["error"] as? String {
                onCancel()
                dismiss()
            }
        }
    }
}

// MARK: - Web View Representable

struct WebViewRepresentable: UIViewRepresentable {
    let htmlContent: String
    let onResult: ([String: Any]) -> Void
    let onLoadingChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult, onLoadingChange: onLoadingChange)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(
            context.coordinator,
            name: "paymentResult"
        )

        // 팝업 허용 설정
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .white
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onResult: ([String: Any]) -> Void
        let onLoadingChange: (Bool) -> Void

        init(onResult: @escaping ([String: Any]) -> Void, onLoadingChange: @escaping (Bool) -> Void) {
            self.onResult = onResult
            self.onLoadingChange = onLoadingChange
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView 로딩 완료")
            onLoadingChange(false)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView 로딩 실패: \(error.localizedDescription)")
            onLoadingChange(false)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            print("📩 JavaScript 메시지 수신: \(message.body)")
            guard message.name == "paymentResult",
                  let dict = message.body as? [String: Any] else { return }
            onResult(dict)
        }
    }
}
