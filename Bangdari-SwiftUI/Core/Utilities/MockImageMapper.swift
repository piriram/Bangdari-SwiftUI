import Foundation
import UIKit

// MARK: - Mock Image Mapper

/// 목업 모드에서 서버 이미지 경로를 로컬 Bundle 이미지로 매핑
enum MockImageMapper {

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

    /// 로컬 이미지를 UIImage로 로드
    static func loadLocalImage(for urlString: String?) -> UIImage? {
        guard let imageName = mapToLocalImage(urlString) else { return nil }

        // 파일시스템에서 직접 로드 (Xcode 프로젝트 추가 불필요)
        let baseImagePath = "/Users/ram/25-2/Bangdari-SwiftUI/Bangdari-SwiftUI/proxyman/media/images"
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp"]

        // 카테고리별 폴더 확인
        let folders = ["banners", "estates", "chats", "posts"]

        for folder in folders {
            for ext in imageExtensions {
                let imagePath = "\(baseImagePath)/\(folder)/\(imageName).\(ext)"
                if let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) {
                    print("✅ [MockImageMapper] 이미지 로드 성공: \(imagePath)")
                    return UIImage(data: data)
                }
            }
        }

        print("⚠️ [MockImageMapper] 이미지 로드 실패: \(imageName)")
        return nil
    }

    // MARK: - Private Helpers

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
