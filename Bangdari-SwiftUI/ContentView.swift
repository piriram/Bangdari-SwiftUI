import SwiftUI

struct ContentView: View {
    private enum AuthState {
        case loading    // accessToken 있고, refresh 검증 중
        case loggedIn
        case loggedOut
    }

    @State private var authState: AuthState = KeychainManager.shared.isLoggedIn ? .loading : .loggedOut
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPaymentFlowActive = false
    @State private var pendingLogoutAfterPayment = false
    @State private var pendingLogoutReason: String?

    var body: some View {
        Group {
            switch authState {
            case .loading:
                Color(.systemBackground)
            case .loggedIn:
                MainTabView()
            case .loggedOut:
                LoginView()
            }
        }
        .onAppear {
            if authState == .loading {
                checkToken()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && authState == .loggedIn && !isPaymentFlowActive {
                refreshTokenSilently()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogin)) { _ in
            authState = .loggedIn
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { notification in
            let reason = notification.object as? String ?? "원인 정보 없음"
            if isPaymentFlowActive {
                pendingLogoutAfterPayment = true
                pendingLogoutReason = reason
                print("🔒 [AUTH] 결제 진행 중 로그아웃 예약: \(reason)")
            } else {
                transitionToLoggedOut(reason: reason)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .paymentFlowDidStart)) { _ in
            isPaymentFlowActive = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .paymentFlowDidEnd)) { _ in
            isPaymentFlowActive = false
            if pendingLogoutAfterPayment {
                let deferredReason = pendingLogoutReason ?? "결제 플로우 종료 후 로그아웃 처리"
                transitionToLoggedOut(reason: "\(deferredReason) (결제 플로우 종료 후 적용)")
                pendingLogoutAfterPayment = false
                pendingLogoutReason = nil
            }
        }
    }

    /// 앱 시작 시 토큰 검증 (loading 상태에서 호출)
    private func checkToken() {
        Task {
            do {
                try await NetworkService.shared.validateAndRefreshToken()
                authState = .loggedIn
            } catch NetworkError.refreshTokenExpired {
                transitionToLoggedOut(reason: "앱 시작 토큰 검증 실패: refreshTokenExpired")
            } catch {
                // 네트워크 단절 등 기타 에러 → 기존 토큰으로 진행 (API 시점에서 갱신 재시도)
                authState = .loggedIn
            }
        }
    }

    /// foreground 복귀 시 백그라운드 silent refresh
    private func refreshTokenSilently() {
        Task {
            do {
                try await NetworkService.shared.validateAndRefreshToken()
            } catch NetworkError.refreshTokenExpired {
                transitionToLoggedOut(reason: "포그라운드 복귀 토큰 검증 실패: refreshTokenExpired")
            } catch {
                // 기타 에러는 무시 (다음 API 호출 시 자동 갱신 로직이 처리)
            }
        }
    }

    private func transitionToLoggedOut(reason: String) {
        print("🔒 [AUTH] 로그인 화면 전환 원인: \(reason)")
        authState = .loggedOut
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MainView()
            }
            .tag(MainTab.home)

            NavigationStack {
                CommunityListView()
            }
            .tag(MainTab.community)

            NavigationStack {
                EstateListView(mode: .liked)
            }
            .tag(MainTab.like)

            NavigationStack {
                MyPageView()
            }
            .tag(MainTab.my)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .onChange(of: selectedTab) { _, _ in
            VideoPlayerManager.shared.pause()
        }
    }

    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 0) {
                tabButton(.home, title: "홈")
                tabButton(.community, title: "커뮤니티")
                tabButton(.like, title: "관심매물")
                tabButton(.my, title: "설정")
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.gray0)
        }
        .background(Color.gray0)
    }

    private func tabButton(_ tab: MainTab, title: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 6) {
                tabIcon(for: tab)
                    .font(.system(size: 20, weight: .medium))

                Text(title)
                    .font(.pretendard(.caption2, .medium))
                    .lineLimit(1)
            }
            .foregroundColor(selectedTab == tab ? Color.gray90 : Color.gray45)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tabIcon(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            Image(selectedTab == .home ? "TabHomeFill" : "TabHomeEmpty")
                .renderingMode(.template)
        case .community:
            Image(systemName: selectedTab == .community ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                .renderingMode(.template)
        case .like:
            Image(selectedTab == .like ? "TabLikeFill" : "TabLikeEmpty")
                .renderingMode(.template)
        case .my:
            Image(selectedTab == .my ? "TabMyFill" : "TabMyEmpty")
                .renderingMode(.template)
        }
    }
}

private enum MainTab {
    case home
    case community
    case like
    case my
}

// MARK: - Notifications

extension Notification.Name {
    static let didLogin = Notification.Name("didLogin")
    static let didLogout = Notification.Name("didLogout")
    static let paymentFlowDidStart = Notification.Name("paymentFlowDidStart")
    static let paymentFlowDidEnd = Notification.Name("paymentFlowDidEnd")
}

#Preview {
    ContentView()
}
