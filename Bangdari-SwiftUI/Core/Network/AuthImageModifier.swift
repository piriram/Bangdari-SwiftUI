import Foundation
import Kingfisher

// MARK: - Auth Image Modifier

struct AuthImageModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        var request = request
        request.setValue(Secrets.sesacKey, forHTTPHeaderField: "SeSACKey")
        if let token = KeychainManager.shared.accessToken {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

// MARK: - Convenience Extension

extension KFImage {
    /// 인증 헤더가 포함된 KFImage 생성
    static func auth(url: URL?) -> KFImage {
        KFImage(url)
            .requestModifier(AuthImageModifier())
    }
}
