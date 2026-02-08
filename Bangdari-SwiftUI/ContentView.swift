import SwiftUI

struct ContentView: View {
    private enum AuthState {
        case loading    // accessToken 있고, refresh 검증 중
        case loggedIn
        case loggedOut
    }

    @State private var authState: AuthState = KeychainManager.shared.isLoggedIn ? .loading : .loggedOut
    @Environment(\.scenePhase) private var scenePhase

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
            if newPhase == .active && authState == .loggedIn {
                refreshTokenSilently()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogin)) { _ in
            authState = .loggedIn
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
            authState = .loggedOut
        }
    }

    /// 앱 시작 시 토큰 검증 (loading 상태에서 호출)
    private func checkToken() {
        Task {
            do {
                try await NetworkService.shared.validateAndRefreshToken()
                authState = .loggedIn
            } catch NetworkError.refreshTokenExpired {
                authState = .loggedOut
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
                authState = .loggedOut
            } catch {
                // 기타 에러는 무시 (다음 API 호출 시 자동 갱신 로직이 처리)
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home

    init() {
        configureTabBarAppearance()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MainView()
            }
            .tabItem {
                Image(selectedTab == .home ? "TabHomeFill" : "TabHomeEmpty")
                    .renderingMode(.template)
                Text("홈")
            }
            .tag(MainTab.home)

            NavigationStack {
                CommunityListView()
            }
            .tabItem {
                Image(systemName: selectedTab == .community ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    .renderingMode(.template)
                Text("커뮤니티")
            }
            .tag(MainTab.community)

            NavigationStack {
                EstateListView(mode: .liked)
            }
            .tabItem {
                Image(selectedTab == .like ? "TabLikeFill" : "TabLikeEmpty")
                    .renderingMode(.template)
                Text("관심매물")
            }
            .tag(MainTab.like)

            NavigationStack {
                MyPageView()
            }
            .tabItem {
                Image(selectedTab == .my ? "TabMyFill" : "TabMyEmpty")
                    .renderingMode(.template)
                Text("설정")
            }
            .tag(MainTab.my)
        }
        .onChange(of: selectedTab) { _, _ in
            VideoPlayerManager.shared.pause()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.gray0)

        // 비선택 아이템 색상 (gray45)
        let normalItemAppearance = UITabBarItemAppearance()
        normalItemAppearance.normal.iconColor = UIColor(Color.gray45)
        normalItemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gray45)
        ]

        // 선택 아이템 색상 (gray90)
        normalItemAppearance.selected.iconColor = UIColor(Color.gray90)
        normalItemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.gray90)
        ]

        appearance.stackedLayoutAppearance = normalItemAppearance
        appearance.inlineLayoutAppearance = normalItemAppearance
        appearance.compactInlineLayoutAppearance = normalItemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
}

#Preview {
    ContentView()
}
