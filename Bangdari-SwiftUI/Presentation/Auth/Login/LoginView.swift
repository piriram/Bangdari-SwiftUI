import SwiftUI
import AuthenticationServices
import KakaoSDKUser
import KakaoSDKAuth

// MARK: - Login View

struct LoginView: View {
    private enum Field {
        case email
        case password
    }

    @StateObject private var intent = LoginIntent()
    @State private var showSignUp = false
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    credentialSection
                    socialSection
                    signUpLink
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }
            .background(decorativeBackground)
            .onTapGesture {
                focusedField = nil
            }
            .disabled(intent.state.isLoading)
            .overlay {
                if intent.state.isLoading {
                    ZStack {
                        Color.black.opacity(0.1)
                            .ignoresSafeArea()

                        ProgressView("로그인 중...")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.gray0)
                            .cornerRadius(12)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    // MARK: - Background

    private var decorativeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.brightCream.opacity(0.35),
                    Color.gray0,
                    Color.brightCoast.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.deepCoast.opacity(0.12))
                .frame(width: 220)
                .blur(radius: 20)
                .offset(x: 150, y: -260)

            Circle()
                .fill(Color.deepWood.opacity(0.08))
                .frame(width: 180)
                .blur(radius: 24)
                .offset(x: -140, y: 320)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.deepCoast.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "house.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.deepCoast)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("방다리")
                        .font(.pretendard(.title1, .bold))
                        .foregroundColor(.deepWood)

                    Text("원하는 방을 가장 빠르게 찾는 방법")
                        .font(.pretendard(.body3))
                        .foregroundColor(.gray75)
                }
            }

            HStack(spacing: 8) {
                featurePill("실거래 기반")
                featurePill("맞춤 추천")
                featurePill("빠른 탐색")
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.deepCoast.opacity(0.08))
                .frame(height: 84)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("실거래 데이터 기반 추천")
                            .font(.pretendard(.body2, .semiBold))
                            .foregroundColor(.deepCoast)

                        Text("로그인 후 맞춤 매물과 실시간 소식을 확인해보세요")
                            .font(.pretendard(.caption1))
                            .foregroundColor(.gray75)
                    }
                    .padding(.horizontal, 16)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func featurePill(_ title: String) -> some View {
        Text(title)
            .font(.pretendard(.caption1, .medium))
            .foregroundColor(.deepWood)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.gray0.opacity(0.8))
            .overlay(
                Capsule()
                    .stroke(Color.gray30, lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    // MARK: - Credential Section

    private var credentialSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("이메일")
                    .font(.pretendard(.caption1, .medium))
                    .foregroundColor(.gray75)

                TextField("이메일을 입력하세요", text: Binding(
                    get: { intent.state.email },
                    set: { intent.updateEmail($0) }
                ))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color.gray15)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .email ? Color.deepCoast : Color.gray30, lineWidth: 1)
                )
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("비밀번호")
                    .font(.pretendard(.caption1, .medium))
                    .foregroundColor(.gray75)

                SecureField("비밀번호를 입력하세요", text: Binding(
                    get: { intent.state.password },
                    set: { intent.updatePassword($0) }
                ))
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    Task { await intent.login() }
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(Color.gray15)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .password ? Color.deepCoast : Color.gray30, lineWidth: 1)
                )
                .cornerRadius(12)
            }

            if let error = intent.state.errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.pretendard(.caption1))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.red.opacity(0.08))
                .cornerRadius(10)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("오류: \(error)")
            }

            Button {
                focusedField = nil
                Task { await intent.login() }
            } label: {
                Text("이메일로 로그인")
                    .font(.pretendard(.body1, .semiBold))
                    .foregroundColor(.gray0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(intent.state.canSubmit ? Color.deepCoast : Color.gray45)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(intent.state.canSubmit ? Color.deepCoast.opacity(0.6) : Color.gray45, lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .shadow(
                        color: intent.state.canSubmit ? Color.deepCoast.opacity(0.24) : .clear,
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            }
            .disabled(!intent.state.canSubmit)
            .accessibilityHint("이메일과 비밀번호를 입력한 뒤 로그인합니다")
        }
        .padding(18)
        .background(Color.gray0.opacity(0.95))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray30, lineWidth: 1)
        )
        .shadow(color: Color.deepWood.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Social Section

    private var socialSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.gray30)
                    .frame(height: 1)

                Text("또는")
                    .font(.pretendard(.caption1))
                    .foregroundColor(.gray60)

                Rectangle()
                    .fill(Color.gray30)
                    .frame(height: 1)
            }

            Button {
                Task { await handleKakaoLogin() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                    Text("카카오로 시작하기")
                        .font(.pretendard(.body2, .semiBold))
                }
                .foregroundColor(.gray100)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 254 / 255, green: 229 / 255, blue: 0 / 255))
                .cornerRadius(12)
            }
            .accessibilityHint("카카오 계정으로 로그인합니다")

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
        .padding(16)
        .background(Color.gray0.opacity(0.9))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray30, lineWidth: 1)
        )
    }

    // MARK: - SignUp Link

    private var signUpLink: some View {
        Button {
            showSignUp = true
        } label: {
            HStack(spacing: 4) {
                Text("계정이 없으신가요?")
                    .font(.pretendard(.body3))
                    .foregroundColor(.gray75)

                Text("회원가입")
                    .font(.pretendard(.body3, .semiBold))
                    .foregroundColor(.deepCoast)
            }
        }
    }

    // MARK: - Helper Methods

    private func handleKakaoLogin() async {
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                if let error = error {
                    print("카카오톡 로그인 실패: \(error)")
                    self.intent.setErrorMessage("카카오톡 로그인에 실패했습니다.")
                } else if let token = oauthToken {
                    Task {
                        await self.intent.loginWithKakao(accessToken: token.accessToken)
                    }
                }
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                if let error = error {
                    print("카카오 계정 로그인 실패: \(error)")
                    self.intent.setErrorMessage("카카오 로그인에 실패했습니다.")
                } else if let token = oauthToken {
                    Task {
                        await self.intent.loginWithKakao(accessToken: token.accessToken)
                    }
                }
            }
        }
    }

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
                return
            }
            intent.setErrorMessage("애플 로그인 중 오류가 발생했습니다.")
        }
    }
}

#Preview {
    LoginView()
}
