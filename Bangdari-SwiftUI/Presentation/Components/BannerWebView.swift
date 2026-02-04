import SwiftUI
import WebKit

// MARK: - Banner WebView (UIViewRepresentable)

struct BannerWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        var request = URLRequest(url: url)
        request.setValue(APIConfig.sesacKey, forHTTPHeaderField: "SeSACKey")
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

// MARK: - Banner WebView Screen (모달용)

struct BannerWebViewScreen: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BannerWebView(url: url)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray90)
                        }
                    }
                }
        }
    }
}
