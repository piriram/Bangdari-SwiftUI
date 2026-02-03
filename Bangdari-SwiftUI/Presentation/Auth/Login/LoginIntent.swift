import Foundation
import Combine
import AuthenticationServices

// MARK: - Login State

struct LoginState {
    var email: String = "judy@ma.com"
    var password: String = "wbel@1234"
    var isLoading: Bool = false
    var errorMessage: String?
    var isLoginSuccess: Bool = false

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

// MARK: - Login Intent

@MainActor
final class LoginIntent: ObservableObject {
    @Published private(set) var state = LoginState()

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository? = nil) {
        self.authRepository = authRepository ?? DIContainer.shared.makeAuthRepository()
    }

    // MARK: - Actions

    func updateEmail(_ email: String) {
        state.email = email
    }

    func updatePassword(_ password: String) {
        state.password = password
    }

    func login() async {
        guard state.canSubmit else { return }

        state.isLoading = true
        state.errorMessage = nil

        let request = LoginRequest(
            email: state.email,
            password: state.password
        )

        do {
            _ = try await authRepository.login(request: request)
            state.isLoginSuccess = true
            NotificationCenter.default.post(name: .didLogin, object: nil)
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "로그인 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func loginWithApple(idToken: String) async {
        state.isLoading = true
        state.errorMessage = nil

        let request = AppleLoginRequest(
            idToken: idToken,
            deviceToken: nil
        )

        do {
            _ = try await authRepository.loginApple(request: request)
            state.isLoginSuccess = true
            NotificationCenter.default.post(name: .didLogin, object: nil)
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "애플 로그인 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func loginWithKakao(accessToken: String) async {
        state.isLoading = true
        state.errorMessage = nil

        let request = KakaoLoginRequest(
            accessToken: accessToken,
            deviceToken: nil
        )

        do {
            _ = try await authRepository.loginKakao(request: request)
            state.isLoginSuccess = true
            NotificationCenter.default.post(name: .didLogin, object: nil)
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "카카오 로그인 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func setErrorMessage(_ message: String) {
        state.errorMessage = message
    }

    func clearError() {
        state.errorMessage = nil
    }
}
