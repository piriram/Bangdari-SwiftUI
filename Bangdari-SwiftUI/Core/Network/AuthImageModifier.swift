import Foundation
import Kingfisher
import SwiftUI

// MARK: - Auth Image Modifier

struct AuthImageModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        var request = request
        let hasToken = KeychainManager.shared.accessToken != nil

        if let url = request.url {
            request.url = normalizedImageURL(url)
        }

//        print("🖼️ [IMG] URL: \(request.url?.absoluteString ?? "nil")")
//        print("🖼️ [IMG] Token 존재: \(hasToken)")

        request.setValue(Secrets.sesacKey, forHTTPHeaderField: "SeSACKey")
        if let token = KeychainManager.shared.accessToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func normalizedImageURL(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("⚠️ [IMG-NORMALIZE] URLComponents 파싱 실패")
            return url
        }

        let originalPath = components.path
        var path = components.path

        // 이중 슬래시 제거
        while path.contains("//") {
            path = path.replacingOccurrences(of: "//", with: "/")
        }

        // /data/ 경로 → /v1/data/ 변환
        if path.hasPrefix("/data/") {
            components.path = "/v1" + path
//            print("🔧 [IMG-NORMALIZE] /data/ 경로 변환")
//            print("  - Original: \(url.absoluteString)")
//            print("  - Path Before: \(originalPath)")
//            print("  - Path After: \(components.path)")
//            print("  - Final URL: \(components.url?.absoluteString ?? "nil")")
        } else {
            components.path = path
        }

        return components.url ?? url
    }
}

// MARK: - Convenience Extension

extension KFImage {
    /// 인증 헤더가 포함된 KFImage 생성
    static func auth(url: URL?) -> KFImage {
//        print("🖼️ [IMG] KFImage.auth 호출 - URL: \(url?.absoluteString ?? "nil")")
        return KFImage(url)
            .requestModifier(AuthImageModifier())
            .onFailure { error in
                print("❌ [IMG] 로딩 실패: \(error.localizedDescription)")
            }
            .onSuccess { result in
//                print("✅ [IMG] 로딩 성공: \(result.source.url?.lastPathComponent ?? "")")
            }
    }
}
