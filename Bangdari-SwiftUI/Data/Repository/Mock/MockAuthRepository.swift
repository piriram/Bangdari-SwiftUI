import Foundation

// MARK: - Mock Auth Repository

final class MockAuthRepository: AuthRepository {

    // MARK: - Mock User Data

    private let mockAuthResponse = AuthResponse(
        user_id: "mock_user_123",
        email: "mock@example.com",
        nick: "목업유저",
        profileImage: nil,
        accessToken: "mock_access_token_12345",
        refreshToken: "mock_refresh_token_67890"
    )

    // MARK: - Auth Methods

    func validateEmail(_ email: String) async throws {
        // Mock에서는 항상 유효한 이메일로 처리
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
    }

    func join(request: JoinRequest) async throws -> AuthResponse {
        // Mock에서는 항상 성공
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 딜레이
        return mockAuthResponse
    }

    func login(request: LoginRequest) async throws -> AuthResponse {
        // Mock에서는 어떤 이메일/비밀번호든 자동 로그인
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 딜레이
        return mockAuthResponse
    }

    func loginApple(request: AppleLoginRequest) async throws -> AuthResponse {
        // Mock에서는 항상 성공
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 딜레이
        return mockAuthResponse
    }

    func loginKakao(request: KakaoLoginRequest) async throws -> AuthResponse {
        // Mock에서는 항상 성공
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 딜레이
        return mockAuthResponse
    }

    func logout() async throws {
        // Mock에서는 아무것도 하지 않음
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 딜레이
    }
}
