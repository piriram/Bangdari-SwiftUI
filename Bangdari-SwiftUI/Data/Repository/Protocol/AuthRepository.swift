import Foundation

// MARK: - Auth Repository Protocol

protocol AuthRepository {
    func validateEmail(_ email: String) async throws
    func join(request: JoinRequest) async throws -> AuthResponse
    func login(request: LoginRequest) async throws -> AuthResponse
    func loginApple(request: AppleLoginRequest) async throws -> AuthResponse
    func loginKakao(request: KakaoLoginRequest) async throws -> AuthResponse
    func logout() async throws
}
