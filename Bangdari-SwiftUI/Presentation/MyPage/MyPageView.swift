import SwiftUI

// MARK: - My Page View

struct MyPageView: View {
    @State private var showLogoutAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository = RemoteAuthRepository()) {
        self.authRepository = authRepository
    }

    var body: some View {
        List {
            Section("프로필") {
                NavigationLink {
                    ProfileEditView()
                } label: {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("프로필 수정")
                    }
                }
            }

            Section("채팅") {
                NavigationLink {
                    ChatRoomListView()
                } label: {
                    HStack {
                        Image(systemName: "message")
                        Text("채팅 목록")
                    }
                }
            }

            Section("개발") {
                NavigationLink {
                    ServerLogView()
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Text("서버 요청 로그")
                    }
                }
            }

            // 로그아웃 버튼
            Section {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("로그아웃")
                    }
                }
            }
        }
        .standardNavigationBar(title: "MY")
        .alert("로그아웃", isPresented: $showLogoutAlert) {
            Button("취소", role: .cancel) {}
            Button("로그아웃", role: .destructive) {
                Task { await logout() }
            }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
        .alert("오류", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Actions

    private func logout() async {
        do {
            try await authRepository.logout()
            NotificationCenter.default.post(name: .didLogout, object: nil)
        } catch {
            errorMessage = "로그아웃 중 오류가 발생했습니다."
            showErrorAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
}
