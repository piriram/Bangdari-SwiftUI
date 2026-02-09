import Foundation

// MARK: - Mock Estate Repository

final class MockEstateRepository: EstateRepository {

    // MARK: - Home

    func fetchTodayEstates() async throws -> [EstateSummaryResponse] {
        try loadJSON(filename: "today-estates")
    }

    func fetchHotEstates() async throws -> [EstateSummaryResponse] {
        try loadJSON(filename: "hot-estates")
    }

    func fetchTodayTopic() async throws -> [EstateTopic] {
        try loadJSON(filename: "today-topic")
    }

    func fetchMainBanners() async throws -> [Banner] {
        try loadJSON(filename: "banners-main")
    }

    // MARK: - List

    func fetchEstatesByLocation(
        latitude: Double,
        longitude: Double,
        maxDistance: Int,
        category: String?
    ) async throws -> [EstateSummaryResponse] {
        try loadJSON(filename: "geolocation")
    }

    func fetchMyLikedEstates(
        next: String?,
        limit: Int?,
        category: String?
    ) async throws -> EstatePaginationResponse {
        // 빈 페이지네이션 응답 반환 (next_cursor: "0"은 마지막 페이지)
        return EstatePaginationResponse(data: [], next_cursor: "0")
    }

    // MARK: - Detail

    func fetchEstateDetail(estateId: String) async throws -> EstateDetailResponse {
        // 샘플 ID 중 하나 사용
        let filename = "estate-detail-6938d207cd1a3725c019c8d8"
        return try loadJSON(filename: filename)
    }

    func toggleLike(estateId: String, like: Bool) async throws -> Bool {
        // Mock에서는 항상 성공
        return like
    }

    func fetchSimilarEstates() async throws -> [EstateSummaryResponse] {
        try loadJSON(filename: "similar-estates")
    }

    // MARK: - Comment

    func createComment(estateId: String, content: String, parentId: String?) async throws {
        // Mock에서는 아무것도 하지 않음
    }

    func updateComment(estateId: String, commentId: String, content: String) async throws {
        // Mock에서는 아무것도 하지 않음
    }

    func deleteComment(estateId: String, commentId: String) async throws {
        // Mock에서는 아무것도 하지 않음
    }

    // MARK: - Helper

    /// 이미지 경로를 로컬 파일 URL로 변환 (JSON 수정)
    private func convertImagePathsInJSON(_ data: Data) throws -> Data {
        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              var dataArray = json["data"] as? [[String: Any]] else {
            // data 래핑이 없으면 그대로 반환
            return data
        }

        let baseImagePath = "file:///Users/ram/25-2/Bangdari-SwiftUI/Bangdari-SwiftUI/proxyman/media/images"
        let folders = ["banners": "banners", "estates": "estates", "chats": "chats", "posts": "posts"]

        // 각 항목의 files/thumbnails 필드 변환
        for (index, var item) in dataArray.enumerated() {
            if let files = item["files"] as? [String] {
                item["files"] = files.compactMap { originalPath -> String? in
                    guard let imageName = MockImageMapper.mapToLocalImage(originalPath) else { return nil }

                    // 카테고리 감지
                    var folder = "estates" // 기본값
                    if originalPath.contains("/banners/") { folder = "banners" }
                    else if originalPath.contains("/chats/") { folder = "chats" }
                    else if originalPath.contains("/posts/") { folder = "posts" }

                    return "\(baseImagePath)/\(folder)/\(imageName).jpg"
                }
                dataArray[index] = item
            } else if let thumbnails = item["thumbnails"] as? [String] {
                item["thumbnails"] = thumbnails.compactMap { originalPath -> String? in
                    guard let imageName = MockImageMapper.mapToLocalImage(originalPath) else { return nil }

                    var folder = "estates"
                    if originalPath.contains("/banners/") { folder = "banners" }
                    else if originalPath.contains("/chats/") { folder = "chats" }
                    else if originalPath.contains("/posts/") { folder = "posts" }

                    return "\(baseImagePath)/\(folder)/\(imageName).jpg"
                }
                dataArray[index] = item
            }
        }

        json["data"] = dataArray
        return try JSONSerialization.data(withJSONObject: json)
    }

    private func loadJSON<T: Decodable>(filename: String) throws -> T {
        print("🔍 [MockEstateRepository] loadJSON 시작: \(filename)")

        // 1. Bundle에서 파일 찾기 (subdirectory 없이)
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("❌ [MockEstateRepository] 파일을 찾을 수 없음: \(filename).json")
            print("   - 검색 경로: MockData/\(filename).json")

            // 디버깅: Bundle의 모든 리소스 출력
            if let resourcePath = Bundle.main.resourcePath {
                print("   - Bundle Resource Path: \(resourcePath)")
                let mockDataPath = (resourcePath as NSString).appendingPathComponent("MockData")
                if FileManager.default.fileExists(atPath: mockDataPath) {
                    print("   - MockData 폴더 존재함")
                    if let files = try? FileManager.default.contentsOfDirectory(atPath: mockDataPath) {
                        print("   - MockData 폴더 내용: \(files.prefix(5))")
                    }
                } else {
                    print("   - ⚠️ MockData 폴더가 Bundle에 없음!")
                }
            }

            throw MockError.fileNotFound(filename)
        }

        print("✅ [MockEstateRepository] 파일 찾음: \(url.path)")

        // 2. 데이터 로드
        var data = try Data(contentsOf: url)
        print("✅ [MockEstateRepository] 데이터 로드 성공: \(data.count) bytes")

        // 3. 이미지 경로 변환 (Mock 모드)
        data = try convertImagePathsInJSON(data)
        print("✅ [MockEstateRepository] 이미지 경로 변환 완료")

        let decoder = JSONDecoder()
        // keyDecodingStrategy 제거 - JSON과 DTO 모두 snake_case 사용

        do {
            // 먼저 APIResponse로 래핑된 형태 시도
            print("🔄 [MockEstateRepository] APIResponse<T> 디코딩 시도...")
            let response = try decoder.decode(APIResponse<T>.self, from: data)
            print("✅ [MockEstateRepository] 디코딩 성공 (APIResponse)")
            return response.data
        } catch let apiError {
            // 실패하면 직접 디코딩 시도
            print("⚠️ [MockEstateRepository] APIResponse 디코딩 실패: \(apiError.localizedDescription)")
            print("🔄 [MockEstateRepository] T 직접 디코딩 시도...")

            do {
                let result = try decoder.decode(T.self, from: data)
                print("✅ [MockEstateRepository] 디코딩 성공 (직접)")
                return result
            } catch let directError {
                print("❌ [MockEstateRepository] 모든 디코딩 실패")
                print("   - APIResponse 에러: \(apiError)")
                print("   - 직접 디코딩 에러: \(directError)")
                throw directError
            }
        }
    }
}

// MARK: - Mock Error

enum MockError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Mock 데이터 파일을 찾을 수 없습니다: \(filename).json"
        }
    }
}

// MARK: - API Response Wrapper

private struct APIResponse<T: Decodable>: Decodable {
    let data: T
}
