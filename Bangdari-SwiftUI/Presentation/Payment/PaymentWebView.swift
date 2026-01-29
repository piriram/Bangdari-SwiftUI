import SwiftUI
import WebKit

// MARK: - Payment Web View

struct PaymentWebView: View {
    @StateObject private var viewModel: PaymentWebViewModel
    @Environment(\.dismiss) private var dismiss

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
            WebViewRepresentable(
                htmlContent: viewModel.htmlContent,
                onResult: handlePaymentResult
            )
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

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(
            context.coordinator,
            name: "paymentResult"
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onResult: ([String: Any]) -> Void

        init(onResult: @escaping ([String: Any]) -> Void) {
            self.onResult = onResult
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "paymentResult",
                  let dict = message.body as? [String: Any] else { return }
            onResult(dict)
        }
    }
}
