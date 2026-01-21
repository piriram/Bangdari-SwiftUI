import Combine
import Foundation

// MARK: - SignUp State

struct SignUpState {
    var email: String = ""
    var password: String = ""
    var passwordConfirm: String = ""
    var nick: String = ""
    var phoneNum: String = ""

    var isEmailValid: Bool = false
    var isEmailChecked: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var isSignUpSuccess: Bool = false

    // 비밀번호 규칙: 최소 8자, 영문+숫자+특수문자 각 1개 이상
    var isPasswordValid: Bool {
        let regex = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,}$"
        return password.range(of: regex, options: .regularExpression) != nil
    }

    var isPasswordMatch: Bool {
        !password.isEmpty && password == passwordConfirm
    }

    // 닉네임 규칙: 특수문자 포함 불가
    var isNickValid: Bool {
        let invalidChars = CharacterSet(charactersIn: "-.,?*-@+^${}()|[]\\")
        return !nick.isEmpty && nick.rangeOfCharacter(from: invalidChars) == nil
    }

    var canSubmit: Bool {
        isEmailChecked && isPasswordValid && isPasswordMatch && isNickValid
    }
}

// MARK: - SignUp Intent

@MainActor
final class SignUpIntent: ObservableObject {
    @Published private(set) var state = SignUpState()

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository? = nil) {
        self.authRepository = authRepository ?? DIContainer.shared.makeAuthRepository()
    }

    // MARK: - Actions

    func updateEmail(_ email: String) {
        state.email = email
        state.isEmailChecked = false
        state.isEmailValid = false
    }

    func updatePassword(_ password: String) {
        state.password = password
    }

    func updatePasswordConfirm(_ confirm: String) {
        state.passwordConfirm = confirm
    }

    func updateNick(_ nick: String) {
        state.nick = nick
    }

    func updatePhoneNum(_ phone: String) {
        state.phoneNum = phone
    }

    func checkEmail() async {
        guard !state.email.isEmpty else {
            state.errorMessage = "이메일을 입력해주세요."
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            try await authRepository.validateEmail(state.email)
            state.isEmailValid = true
            state.isEmailChecked = true
        } catch let error as NetworkError {
            state.errorMessage = error.message
            state.isEmailValid = false
        } catch {
            state.errorMessage = "이메일 확인 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func signUp() async {
        guard state.canSubmit else { return }

        state.isLoading = true
        state.errorMessage = nil

        let request = JoinRequest(
            email: state.email,
            password: state.password,
            nick: state.nick,
            phoneNum: state.phoneNum.isEmpty ? nil : state.phoneNum,
            introduction: nil,
            deviceToken: nil
        )

        do {
            _ = try await authRepository.join(request: request)
            state.isSignUpSuccess = true
            NotificationCenter.default.post(name: .didLogin, object: nil)
        } catch let error as NetworkError {
            state.errorMessage = error.message
        } catch {
            state.errorMessage = "회원가입 중 오류가 발생했습니다."
        }

        state.isLoading = false
    }

    func clearError() {
        state.errorMessage = nil
    }
}
