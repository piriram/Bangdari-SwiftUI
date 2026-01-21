import SwiftUI

// MARK: - SignUp View

struct SignUpView: View {
    @StateObject private var intent = SignUpIntent()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 이메일
                emailSection

                // 비밀번호
                passwordSection

                // 닉네임
                nickSection

                // 전화번호 (선택)
                phoneSection

                // 에러 메시지
                if let error = intent.state.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                // 회원가입 버튼
                signUpButton
            }
            .padding(20)
        }
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(intent.state.isLoading)
        .overlay {
            if intent.state.isLoading {
                ProgressView()
            }
        }
        .onChange(of: intent.state.isSignUpSuccess) { success in
            if success {
                dismiss()
            }
        }
    }

    // MARK: - Email Section

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이메일")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                TextField("이메일을 입력하세요", text: Binding(
                    get: { intent.state.email },
                    set: { intent.updateEmail($0) }
                ))
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

                Button("중복확인") {
                    Task { await intent.checkEmail() }
                }
                .buttonStyle(.bordered)
                .disabled(intent.state.email.isEmpty)
            }

            if intent.state.isEmailChecked && intent.state.isEmailValid {
                Text("사용 가능한 이메일입니다.")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }

    // MARK: - Password Section

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("비밀번호")
                .font(.subheadline)
                .fontWeight(.medium)

            SecureField("비밀번호 (8자 이상, 영문+숫자+특수문자)", text: Binding(
                get: { intent.state.password },
                set: { intent.updatePassword($0) }
            ))
            .textContentType(.newPassword)

            if !intent.state.password.isEmpty && !intent.state.isPasswordValid {
                Text("비밀번호는 8자 이상, 영문/숫자/특수문자를 포함해야 합니다.")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            SecureField("비밀번호 확인", text: Binding(
                get: { intent.state.passwordConfirm },
                set: { intent.updatePasswordConfirm($0) }
            ))
            .textContentType(.newPassword)

            if !intent.state.passwordConfirm.isEmpty && !intent.state.isPasswordMatch {
                Text("비밀번호가 일치하지 않습니다.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Nick Section

    private var nickSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("닉네임을 입력하세요", text: Binding(
                get: { intent.state.nick },
                set: { intent.updateNick($0) }
            ))

            if !intent.state.nick.isEmpty && !intent.state.isNickValid {
                Text("특수문자는 사용할 수 없습니다.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Phone Section

    private var phoneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("전화번호 (선택)")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("전화번호를 입력하세요", text: Binding(
                get: { intent.state.phoneNum },
                set: { intent.updatePhoneNum($0) }
            ))
            .keyboardType(.phonePad)
        }
    }

    // MARK: - SignUp Button

    private var signUpButton: some View {
        Button {
            Task { await intent.signUp() }
        } label: {
            Text("회원가입")
                .frame(maxWidth: .infinity)
                .padding()
                .background(intent.state.canSubmit ? Color.brown : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(!intent.state.canSubmit)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
