import SwiftUI
import AuthenticationServices

// MARK: - Login View

struct LoginView: View {
    @StateObject private var intent = LoginIntent()
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // 로고/타이틀
                titleSection

                // 입력 필드
                inputSection

                // 에러 메시지
                if let error = intent.state.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // 로그인 버튼
                loginButton

                // 소셜 로그인 구분선
                socialDivider

                // 애플 로그인 버튼
                appleLoginButton

                // 회원가입 링크
                signUpLink

                Spacer()
            }
            .padding(20)
            .disabled(intent.state.isLoading)
            .overlay {
                if intent.state.isLoading {
                    ProgressView()
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("방다리")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("원하는 방을 찾아보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 16) {
            TextField("이메일", text: Binding(
                get: { intent.state.email },
                set: { intent.updateEmail($0) }
            ))
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            SecureField("비밀번호", text: Binding(
                get: { intent.state.password },
                set: { intent.updatePassword($0) }
            ))
            .textContentType(.password)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            Task { await intent.login() }
        } label: {
            Text("로그인")
                .frame(maxWidth: .infinity)
                .padding()
                .background(intent.state.canSubmit ? Color.brown : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(!intent.state.canSubmit)
    }

    // MARK: - Social Divider

    private var socialDivider: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)

            Text("또는")
                .font(.caption)
                .foregroundColor(.secondary)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: - Apple Login Button

    private var appleLoginButton: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.email, .fullName]
            },
            onCompletion: { result in
                Task {
                    await handleAppleSignIn(result)
                }
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(12)
    }

    // MARK: - SignUp Link

    private var signUpLink: some View {
        Button {
            showSignUp = true
        } label: {
            HStack(spacing: 4) {
                Text("계정이 없으신가요?")
                    .foregroundColor(.secondary)
                Text("회원가입")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Helper Methods

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                intent.setErrorMessage("애플 로그인 정보를 가져올 수 없습니다.")
                return
            }

            await intent.loginWithApple(idToken: idTokenString)

        case .failure(let error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                // 사용자가 취소한 경우 에러 메시지 표시하지 않음
                return
            }
            intent.setErrorMessage("애플 로그인 중 오류가 발생했습니다.")
        }
    }
}

#Preview {
    LoginView()
}
