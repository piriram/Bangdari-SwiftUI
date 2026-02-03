import Foundation

// MARK: - Request

struct EmailValidationRequest: Encodable {
    let email: String
}

struct JoinRequest: Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String?
    let introduction: String?
    let deviceToken: String?
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct AppleLoginRequest: Encodable {
    let idToken: String
    let deviceToken: String?
}

struct KakaoLoginRequest: Encodable {
    let oauthToken: String
    let deviceToken: String?
}

// MARK: - Response

struct AuthResponse: Decodable {
    let user_id: String
    let email: String
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
}

struct MessageResponse: Decodable {
    let message: String
}
