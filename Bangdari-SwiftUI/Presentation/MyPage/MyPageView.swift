import SwiftUI

// MARK: - My Page View

struct MyPageView: View {
    @State private var showLogoutAlert = false

    var body: some View {
        List {
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
        .navigationTitle("마이페이지")
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
