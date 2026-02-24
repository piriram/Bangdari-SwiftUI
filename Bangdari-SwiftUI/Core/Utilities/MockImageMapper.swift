import Foundation
import UIKit

// MARK: - Mock Image Mapper

/// 목업 모드에서 서버 이미지 경로를 로컬 Bundle 이미지로 매핑
enum MockImageMapper {

    private static let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp"]

    // MARK: - Mock Image Mapping

    /// 서버 이미지 URL을 로컬 이미지 이름으로 변환
    /// - Parameter urlString: 서버 이미지 경로 (예: "/data/estates/estate_111_xxx.png")
    /// - Returns: 로컬 이미지 이름 (예: "estate_1") 또는 nil
    static func mapToLocalImage(_ urlString: String?) -> String? {
        guard let urlString = urlString else { return nil }
        guard AppEnvironment.current == .mock else { return nil }

        // 카테고리별 매핑
        if urlString.contains("/data/banners/") {
            return mapBannerImage(urlString)
        } else if urlString.contains("/data/estates/") {
            return mapEstateImage(urlString)
        } else if urlString.contains("/data/chats/") {
            return mapChatImage(urlString)
        } else if urlString.contains("/data/posts/") {
            return mapPostImage(urlString)
        }

        return nil
    }

    /// 입력 문자열을 기준으로 Bundle 내부 이미지 절대 경로 반환
    static func localImagePath(for urlString: String?) -> String? {
        guard AppEnvironment.current == .mock else { return nil }
        guard let urlString, !urlString.isEmpty else { return nil }

        // 1) 서버 경로(/data/...) → 매핑된 이미지명으로 해석
        if let mappedName = mapToLocalImage(urlString),
           let path = resolveBundleImagePath(imageName: mappedName) {
            return path
        }

        // 2) 이미 파일명이 들어온 경우(estate_1.jpg 등)
        let lastComponent = (urlString as NSString).lastPathComponent
        let filename = (lastComponent as NSString).deletingPathExtension
        let ext = (lastComponent as NSString).pathExtension

        if !filename.isEmpty {
            if !ext.isEmpty,
               let path = Bundle.main.path(forResource: filename, ofType: ext) {
                return path
            }

            if let path = resolveBundleImagePath(imageName: filename) {
                return path
            }
        }

        return nil
    }

    /// 로컬 이미지를 UIImage로 로드
    static func loadLocalImage(for urlString: String?) -> UIImage? {
        guard let imagePath = localImagePath(for: urlString) else { return nil }

        if let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) {
            print("✅ [MockImageMapper] 이미지 로드 성공: \(imagePath)")
            return UIImage(data: data)
        }

        print("⚠️ [MockImageMapper] 이미지 로드 실패: \(imagePath)")
        return nil
    }

    /// 이미지 경로 문자열(로컬/원격 혼재)을 실제 로딩 가능한 URL로 변환
    static func resolvedImageURL(from path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }

        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }

        if path.hasPrefix("file://") {
            return URL(string: path)
        }

        if AppEnvironment.current == .mock {
            if let localPath = localImagePath(for: path) {
                return URL(fileURLWithPath: localPath)
            }

            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        let separator = path.hasPrefix("/") ? "" : "/"
        return URL(string: APIConfig.baseURL + separator + path)
    }

    // MARK: - Private Helpers

    private static func resolveBundleImagePath(imageName: String) -> String? {
        for ext in imageExtensions {
            if let path = Bundle.main.path(forResource: imageName, ofType: ext) {
                return path
            }
        }
        return nil
    }

    private static var estateImageCounter = 0
    private static var bannerImageCounter = 0
    private static var chatImageCounter = 0
    private static var postImageCounter = 0

    private static func mapBannerImage(_ urlString: String) -> String {
        bannerImageCounter = (bannerImageCounter % 4) + 1
        return "banner_\(bannerImageCounter)"
    }

    private static func mapEstateImage(_ urlString: String) -> String {
        // URL 해시값을 이용해서 1~40 범위의 이미지 매핑
        let hash = Int((urlString.hashValue.magnitude % 40)) + 1
        return "estate_\(hash)"
    }

    private static func mapChatImage(_ urlString: String) -> String {
        return "chat_1"
    }

    private static func mapPostImage(_ urlString: String) -> String {
        // URL 해시값을 이용해서 1~11 범위의 이미지 매핑
        let hash = Int((urlString.hashValue.magnitude % 11)) + 1
        return "post_\(hash)"
    }
}

// MARK: - String Extension

extension String {
    /// Mock 모드에서 로컬 이미지로 변환
    var mockLocalImage: UIImage? {
        MockImageMapper.loadLocalImage(for: self)
    }

    /// Mock 모드에서 로컬 이미지 이름
    var mockImageName: String? {
        MockImageMapper.mapToLocalImage(self)
    }
}
