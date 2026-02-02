import Foundation

// MARK: - My Profile Response

/// 내 프로필 조회/수정 응답 (GET/PUT /v1/users/me/profile)
struct MyInfoResponseDTO: Decodable {
    let user_id: String
    let email: String
    let nick: String
    let introduction: String?
    let profileImage: String?
    let phoneNum: String?
}

// MARK: - User Profile Requests

/// 프로필 수정 요청 (PUT /v1/users/me/profile)
struct UpdateProfileRequest: Encodable {
    let nick: String?
    let introduction: String?
    let phoneNum: String?
    let profileImage: String?
}

/// 디바이스 토큰 업데이트 요청 (PUT /v1/users/deviceToken)
struct DeviceTokenRequest: Encodable {
    let deviceToken: String
}

// MARK: - User Search Response

/// 유저 검색 응답 (GET /v1/users/search)
struct UserSearchResponse: Decodable {
    let data: [UserInfo]
}
