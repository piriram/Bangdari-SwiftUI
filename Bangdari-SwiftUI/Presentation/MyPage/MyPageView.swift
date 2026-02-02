import SwiftUI

// MARK: - My Page View

struct MyPageView: View {
    @State private var showLogoutAlert = false

    var body: some View {
        List {
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
                logout()
            }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
    }

    // MARK: - Actions

    private func logout() {
        KeychainManager.shared.clearTokens()
        NotificationCenter.default.post(name: .didLogout, object: nil)
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
}
