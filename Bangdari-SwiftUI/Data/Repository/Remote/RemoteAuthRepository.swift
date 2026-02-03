import Foundation

// MARK: - Remote Auth Repository

final class RemoteAuthRepository: AuthRepository {
    private let network = NetworkService.shared
    private let keychain = KeychainManager.shared

    func validateEmail(_ email: String) async throws {
        let request = EmailValidationRequest(email: email)
        try await network.requestWithoutResponse(.validateEmail, body: request)
    }

    func join(request: JoinRequest) async throws -> AuthResponse {
        let response = try await network.request(.join, body: request, type: AuthResponse.self)

        // 토큰 저장
        keychain.saveTokens(
            access: response.accessToken,
            refresh: response.refreshToken,
            userId: response.user_id
        )

        return response
    }

    func login(request: LoginRequest) async throws -> AuthResponse {
        let response = try await network.request(.login, body: request, type: AuthResponse.self)

        // 토큰 저장
        keychain.saveTokens(
            access: response.accessToken,
            refresh: response.refreshToken,
            userId: response.user_id
        )

        return response
    }

    func loginApple(request: AppleLoginRequest) async throws -> AuthResponse {
        let response = try await network.request(.loginApple, body: request, type: AuthResponse.self)

        // 토큰 저장
        keychain.saveTokens(
            access: response.accessToken,
            refresh: response.refreshToken,
            userId: response.user_id
        )

        return response
    }

    func loginKakao(request: KakaoLoginRequest) async throws -> AuthResponse {
        let response = try await network.request(.loginKakao, body: request, type: AuthResponse.self)

        // 토큰 저장
        keychain.saveTokens(
            access: response.accessToken,
            refresh: response.refreshToken,
            userId: response.user_id
        )

        return response
    }

    func logout() async throws {
        try await network.requestWithoutResponse(.logout)
        keychain.clearTokens()
    }
}
